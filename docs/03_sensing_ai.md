# AI별 — 음향 감지 엔진 (`lib/sensing/`)

> 갱신: 2026-06-09 · 같이 보기: [개요](01_overview.md) · [로직별](02_logic.md)
> 범위: 소리/가속도에서 복약·식사를 *판정*하는 신경망·신호처리·점수 엔진.
> "언제 들을지 / 어느 약으로 칠지"는 [로직 문서](02_logic.md).

---

## 0. 한 줄 요약

"AI"라 부르지만 구조는 **두 신경망(YAMNet, 삼킴 CNN)으로 소리 특징을 뽑고, 그 위에 룰베이스 점수합(0~100점) + 임계값(80점)으로 복약/식사를 판정**하는 하이브리드. 최종 "복용 확정"은 AI가 아니라 **휴리스틱 점수 엔진**이 내린다.

---

## 1. 파이프라인

```
마이크 16kHz mono PCM (audio_streamer: 15600샘플=0.975초 청크)
      ▼  청크 1개마다 (med_sensing_service_io `_onChunk`)
┌───────────────────────────────────────────────────────────┐
│ ① YAMNet (yamnet_classifier) → 521 클래스 점수               │
│     ├ chewingScore → 식사/오탐 신호(M_chew)                  │
│     └ 클래스별 → scorer.addYamnetResult                      │
│ ② IIR 밴드패스 (drink_detector) → 꿀꺽 후보 (순수 Dart)       │
│ ③ 삼킴 CNN (swallow_inference) → 꿀꺽 확률 (logmel 96×64)     │
│     └ 직렬: ②가 후보 잡은 청크에서만 ③ 추론 →                │
│        ③≥0.30이면 scorer.addSwallowDetection                │
│ ④ 가속도계 → scorer.updateAccelerometer                      │
└───────────────────────────────────────────────────────────┘
      ▼
  MedicationScorer (120초 내 점수합 80점 → onTrigger)
      ▼
  _onScorerTrigger → p2: onMedConfirmed(scheduleId, at) → Firestore taken=true
                     (p1: 무시 / gap: 제거됨)
```

서비스 전체는 **flutter_foreground_task 서비스 isolate**에서 돌아 화면이 꺼져도 유지된다.

---

## 2. 모델·신호기 3종

### 2-1. YAMNet (`yamnet_classifier.dart`)
- Google 범용 오디오 분류기. 0.975초 → 521 클래스. 프레임 단순 평균으로 클래스 점수 산출.
- 실제 쓰는 클래스 12개: 물(Water/Tap/Liquid/Slosh/Pour/Fill/Pump), 약봉지(Rattle/Crumpling/Tearing), 기타(Throat clearing/Clicking). 차단신호로 Glass+Dishes.
- `chewingScore()`: 씹기 라벨 → 식사 판정 + 복약 오탐 차단용(M_chew).

### 2-2. 삼킴 CNN (`swallow_inference.dart`)
- 자체 학습 소형 CNN. logmel 패치(96프레임×64 mel, ~960ms) → 삼킴 확률.
- **librosa 호환 직접 재구현**(DFT 트위들 테이블 사전계산, Slaney mel filterbank sparse 상수, periodic Hann). 주석상 librosa와 오차 0.0000 dB.
- [2026-06-09 직렬화] `pushAudio`(버퍼 누적만, 매 청크) + `inferLatest`(추론, 게이트 통과 시만)로 분리. 버퍼는 최근 15600샘플(=1청크=패치 1개) 롤링 유지. 서비스 게이트 임계 `kCnnSwallowThreshold = 0.30`.

### 2-3. IIR 꿀꺽 감지 (`drink_detector.dart`)
- 신경망 아님. 순수 Dart 2차 butterworth 밴드패스 3개 + 3단계 차단:
  1. 고역/저역 ≥ 0.40 → 기침 차단 + 500ms 쿨다운
  2. 중역/저역 > 0.42 → 말소리/키보드 차단
  3. 직전 500ms 급상승 → 의자/충격음 차단
- 자기녹음 7샘플 FFT로 100~1000Hz 대역 튜닝.

---

## 3. 직렬 cascade — IIR → CNN (`_onChunk`)

[2026-06-09] 기존 "병렬 AND"(매 청크 둘 다 돌리고 동시 만족)를 **직렬**로 변경.

```dart
_swallow.pushAudio(chunk);            // ① CNN 버퍼만 누적(추론 X) — 매 청크
final event = _drink.process(chunk);  // ② IIR 1차 게이트 — 매 청크
if (event.detected) {                 // ③ IIR 통과한 청크에서만
  final cnnScore = _swallow.inferLatest(); //   CNN 추론
  if (cnnScore >= kCnnSwallowThreshold) scorer.addSwallowDetection(...);
}
```

- **효율**: 비싼 CNN(TFLite+DFT logmel)이 IIR이 후보 잡은 청크에서만 돈다 → 평소 추론 0회.
- **동등성**: 청크(15600)=패치 길이라, IIR이 뜬 청크 전체가 CNN 분석 창 → 삼킴이 창 안에 온전히 들어옴.
- **트레이드오프**: IIR이 1차 게이트라 IIR이 놓치면 CNN 확인 기회 없음(기존 AND도 IIR 필수였으니 동일).

---

## 4. 핵심 판정 — `MedicationScorer`

복약을 "의식(ritual) 패턴"으로 보고 5개 카테고리 점수를 합산. 각 카테고리는 120초 윈도우 내 **최초 1회만** 가산.

| 카테고리 | 점수 | 무엇으로 |
|---|---|---|
| water (물) | 20 | YAMNet 물 계열 (conf ≥ **0.12**) |
| package (약봉지) | 20 | YAMNet Rattle/Crumpling/Tearing (≥ 0.3) |
| **swallow (목넘김)** | **30** | IIR(밴드패스) 게이트 통과 → CNN ≥ 0.30 (직렬) |
| stationary (정지) | 20 | 가속도계 5초 중 60%↑ 정지 |
| etc (기타) | 10 | Throat clearing / Clicking (≥ 0.3) |
| **합계** | **100** | |

**트리거: 점수합 ≥ 80점** (`kGeminiVerifyThreshold`).
> swallow(30) 없이는 최대 70점이라 80 미달 → **삼킴 감지가 사실상 필수**.

### 차단(negative) 신호 — P2 단계에서 적용
- **foodConflict**: 30초 내 씹기 4회↑ → "식사 중" 차단. 마지막 씹기 후 15초면 해제.
- **dishwashing**: Glass + Dishes/pots 5초 내 동시 → "설거지 중" 차단. 15초 후 해제.

---

## 5. 트리거 → 결과 분기 (`_onScorerTrigger`)

- **p2**(복약 창): `onMedConfirmed(scheduleId, at)` → `taken=true` 확정.
- **p1**(식사 중): 무시(식사 소음과 복약 구분 불가).
- **gap**: 컨트롤러에서 제거됨 → 더 이상 발생하지 않음(`onUnknownMed` 휴면).

---

## 6. ⚠️ 미심쩍은 / 주의할 부분

1. **"Gemini 검증" 이름뿐, 실제 호출 없음 (가장 중요)** — 트리거 타입은 `geminiVerify`지만 2차 확인이 없다. p2면 곧장 `taken=true`. **센서 점수 80점만으로 복용 단정.**
2. **swallow 순서검증(`orderValid`)이 계산만 되고 안 막음** — `_evaluate`는 점수 80만 보고, `_onScorerTrigger`는 orderValid를 안 읽음 → 사실상 죽은 안전장치.
3. **swallow CNN 신뢰도 미확보(자인)** — 80점의 30점이 신뢰도 낮은 신호에 걸림(IIR 직렬로 보완).
4. **stationary 20점이 거의 항상 깔림** — 폰을 책상에 두면 정지로 20점. "정지=복약"이라는 가정 약함.
5. **water 임계 0.12로 낮음** — 배경 물소리에 20점 오탐 위험.
6. **YAMNet drinkingScore 미사용** — 정교한 로직이 실제 경로에서 비활성.
7. **YAMNet 프레임 평균으로 짧은 이벤트 희석** — 딸깍/꿀꺽 같은 순간음이 평균에 묻힘.
8. **scorer가 `DateTime.now()` 내부 호출** — 시간 경계 단위 테스트 어려움(컨트롤러·상태머신은 주입형).
9. **권한 흐름 이원화** — 바인더(알림·배터리) vs 서비스(마이크). 서비스 isolate에서의 마이크 권한 다이얼로그 불확실.
10. **실기기 미검증** — 마이크 감지 정확도/백그라운드 생존 폰 확인 전무.

---

## 7. 검증된 / 잘 된 부분

- 삼킴 CNN 전처리가 librosa와 오차 0dB로 일치(직접 재구현·검증).
- 단위 테스트 통과(phase controller, meal state machine 등 순수 로직).
- CNN+IIR 직렬 교차검증, foodConflict·설거지 차단 등 오탐 억제 다층.
- 책임 분리: scorer/controller는 Firebase를 모르고 콜백으로만 결과 전달 → 테스트·재사용 용이.
