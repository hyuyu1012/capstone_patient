# YAMNet 식사·복약 감지 → capstone_patient 통합 계획

> 분석일: 2026-06-05 · 대상: `~/Desktop/YAMNet` (yamnet_test) → `capstone_patient`
> 본 문서는 **계획/분석 전용**. 실제 코드 이식은 별도 진행.

## 0. 결론 요약

- 이 시스템은 **복약 모니터링(P2)뿐 아니라 식사 모니터링(P1)도** 다룬다.
  하나의 연속된 음향 감시 위에 P1(식사)/gap(공백기)/P2(복약) 단계만 얹은 구조.
- 두 프로젝트 모두 Flutter라 결합 난이도 낮음.
- YAMNet 팀이 **capstone_patient를 명시적으로 타깃**해 설계함
  (`med_result_writer.dart` 주석: "UI 팀 capstone_patient의 schedules/{id} 모델").
- 데이터 경로/필드가 그대로 맞물림:
  - capstone `ScheduleService` → `patients/{patientId}/schedules/{id}` 읽기
  - capstone `ScheduleItem.kind`에 **`med`와 `meal`이 이미 존재** → 식사 항목도 표시 가능
  - 복약: `MedResultWriter.toScheduleUpdate()` → `{taken, takenAt, detectStatus, detectedBy}`
  - 식사: `MedResultWriter.toMealUpdate()` → `{mealStatus, taken, takenAt}`
  - capstone `ScheduleItem`이 읽는 필드 = `{taken, takenAt}` ✅ 정확히 일치
- **감지 성숙도 차이 주의**: 복약(P2)은 점수엔진까지 완성됐지만, 식사(P1)는
  데이터모델·감지재료(M_chew)만 있고 **식사 상태머신(inProgress/eaten 판정)은 미구현**.
- 핵심 작업은 "센서 엔진 이식"이 아니라
  **① P1 식사 상태머신 구현 + ② P1/P2 단계 오케스트레이션 + ③ Firestore write 연결**.

### 0-1. 식사 vs 복약 — 구현 성숙도

| 구분 | 복약 모니터링 (P2) | 식사 모니터링 (P1) |
|---|---|---|
| 데이터 모델 | ✅ `MedStatus` + `toScheduleUpdate` | ✅ `MealStatus` + `toMealUpdate` |
| 감지 재료 | ✅ water/package/swallow/stationary/etc + 점수 | ✅ `chewingScore`(M_chew) |
| 판정 로직 | ✅ `MedicationScorer` 120초 80점 트리거 | ❌ **미구현** — M_chew는 현재 복약 오탐 차단(foodConflict)용으로만 쓰임 |
| 상태머신 | ✅ idle/p1/gap/p2 + 트리거 | ❌ "M_chew 지속→inProgress, 마지막 후 3분 무음→eaten" 주석만 있고 코드 없음 |
| 창 제어 | ❌ 신설 필요 (`setPhase`) | ❌ 신설 필요 |
| Firestore 연결 | ❌ 신설 필요 | ❌ 신설 필요 |

---

## 1. 양쪽 구조

### capstone_patient (현재 앱)
- Flutter + Provider + Firebase(Auth/Firestore) + 로컬알림 + TTS
- 라우팅: `AuthGate`(로그인) → `ClaimScreen`(환자 연결) → `ScheduleScreen`
- `ScheduleService`는 **읽기 전용** — 보호자 앱이 등록한 스케줄을 표시만 함
  (주석: "the sensor team writes taken/missed separately" → 우리가 그 sensor team)
- 데이터: `patients/{id}/schedules/{id}: {kind, name, dose, time, taken, takenAt}`

### YAMNet (yamnet_test, 이식 대상)
센서 파이프라인 (UI는 데모용 `DetectorPage`라 **이식 불필요**, 엔진만 추출):

| 파일 | 역할 |
|---|---|
| `audio_streamer.dart` | 마이크 16kHz mono PCM → 15600샘플 청크 콜백 |
| `yamnet_classifier.dart` | YAMNet tflite, 521클래스 분류 + chew/drink 스코어 |
| `swallow_inference.dart` | 삼킴 CNN (logmel 96×64, librosa 호환) |
| `drink_detector.dart` | 순수 Dart IIR 밴드패스 꿀꺽음 감지 |
| `medication_scorer.dart` | **핵심**. 5카테고리 점수(water/package/swallow/stationary/etc), 120초 윈도우, 80점→트리거, foodConflict·설거지 차단, P1/P2/gap/idle phase |
| `med_result_writer.dart` | 감지결과 → Firestore 맵 변환 (통합 어댑터, 이미 capstone 모델 타깃) |

데이터 흐름:
```
AudioStreamer.onChunk(Float32 15600)
  → YamnetClassifier.classifyIndexed()  → scorer.addYamnetResult(idx, conf)
  → YamnetClassifier.chewingScore()      → scorer.addChewDetection()
  → DrinkDetector.process() (IIR)  ┐ 둘 다 감지 시
  → SwallowDetector.feedFloat32() (CNN) ┘ → scorer.addSwallowDetection()
userAccelerometerEventStream() → scorer.updateAccelerometer()
  → scorer.onTrigger(MedTriggerResult{score, phase, ...})  [80점↑]
```

---

## 2. 충돌/주의 지점

| 항목 | capstone | YAMNet | 조치 |
|---|---|---|---|
| Dart SDK | `^3.11.5` | `>=3.0.0 <4.0.0` | capstone 기준 유지 (상위호환) |
| 의존성 | 없음 | `flutter_sound`, `tflite_flutter`, `permission_handler`, `path_provider`, `sensors_plus` | pubspec에 추가 |
| 에셋 | 폰트만 | `yamnet.tflite`, `yamnet_class_map.csv`, `ml/swallow_classifier.tflite` | `assets/`로 복사 + pubspec 등록 |
| Android 권한 | 알림/알람 | `RECORD_AUDIO`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE` | manifest에 추가 |
| minSdk | `flutter.minSdkVersion`(기본) | flutter_sound는 minSdk 24 요구 | **확인 필요** — minSdk 24로 상향 가능성 |
| 패키지명 | `com.example.capstone_patient` | `com.example.yamnet_test` | capstone 것 유지 (Kotlin MainActivity 이식 불필요) |
| 진입점 | `main.dart`(Firebase 라우팅) | `main.dart`(데모 UI) | YAMNet main.dart **버림**, 엔진만 서비스화 |
| Gemini 검증 | 없음 | 주석엔 있으나 **코드 미구현** | 결정 필요 (3절) |

---

## 3. 결정이 필요한 사항

1. **모니터링 시점/방식**
   - (A) 앱 포그라운드 + 복약 예정시간 근처(P2 창)에만 마이크 가동 — 단순, 배터리/권한 부담↓
   - (B) Android Foreground Service로 상시 감시 — YAMNet 권한엔 준비됨, 구현량↑
   - → 캡스톤 데모 기준이면 (A) 권장.
2. **Gemini 음성 재확인**: scorer는 80점↑ 시 항상 "Gemini 검증" 트리거를 내보내도록 설계됨.
   현재 코드엔 Gemini 호출이 없음. (a) 일단 자동 confirmed 처리 / (b) TTS로 "약 드셨어요?" 확인 후 처리 / (c) 보호자 알림. → 범위 결정 필요.
3. **P1/P2 오케스트레이션 주체**: 스케줄 `time`을 기준으로 식사창(P1)·복약창(P2)을 누가 열고 닫고 `setPhase()`를 호출할지. (스케줄 기반 타이머 컨트롤러 신설)
4. **unknown(gap) 감지 저장소**: `patients/{id}/pendingMeds` 컬렉션 신설 여부 (보호자 앱과 협의).
5. **식사(P1) 구현 범위**: 식사 모니터링을 이번 통합에 포함할지.
   - (A) 포함 — M_chew 기반 식사 상태머신(inProgress/eaten)을 신설하고 `meal` 스케줄 항목에 `toMealUpdate()` 기록.
   - (B) 보류 — 복약(P2)만 먼저 완성하고, 식사는 데이터모델만 둔 채 다음 단계로.
   - → 식사 상태머신이 미구현이라 (A)는 추가 개발이 필요(복약보다 작업량 큼).

---

## 4. 제안 통합 아키텍처

YAMNet UI는 버리고 엔진을 **`MedSensingService`** 하나로 감싸 Provider에 등록.

```
lib/
  sensing/
    audio_streamer.dart        ← YAMNet 그대로 복사
    yamnet_classifier.dart     ← 그대로
    swallow_inference.dart     ← 그대로
    drink_detector.dart        ← 그대로
    medication_scorer.dart     ← 그대로 (순수 로직, 검증됨)
    med_result_writer.dart     ← 그대로 (이미 capstone 모델 타깃)
    med_sensing_service.dart   ← 신규. main.dart의 _onChunk/_init 배선을 서비스로 이전
    med_phase_controller.dart  ← 신규. 스케줄 time → P1/P2/gap/idle setPhase
    meal_state_machine.dart    ← 신규(식사 포함 시). M_chew 지속/무음으로 inProgress/eaten 판정
  data/
    schedule_service.dart      ← setTaken()/setMeal() write 메서드 추가 (현재 읽기전용)
```

- `MedSensingService`: 모델 로드 → 마이크 스트림 → 각 감지기 → scorer 연결.
  복약: `scorer.onTrigger`에서 `result.phase`로 분기:
  - `p2` → `ScheduleService.setTaken(scheduleId, MedResultWriter.toScheduleUpdate(...))`
  - `gap` → `pendingMeds.add(MedResultWriter.toUnknownEvent(...))`
  식사: P1 창에서 M_chew를 `MealStateMachine`에 흘려보내 상태 산출 →
  - `inProgress`/`eaten` → `ScheduleService.setMeal(scheduleId, MedResultWriter.toMealUpdate(...))`
- `MealStateMachine`(식사 포함 시 신규): 현재 scorer의 M_chew는 복약 오탐 차단용일 뿐
  식사 상태를 내지 않으므로, "M_chew 지속→inProgress / 마지막 후 N분 무음→eaten"을 별도 구현.
- `MedPhaseController`: 스케줄의 식사(`kind: meal`)/약(`kind: med`) `time`을 보고
  창을 열며 `scorer.setPhase()` 호출. P1↔gap↔P2 전환을 관장.
- `ScheduleScreen`에서 서비스 구독해 "식사 중.../감지 중/점수" 표시(선택).

---

## 5. 단계별 작업 목록 (이식 시)

1. [ ] `assets/yamnet.tflite`, `assets/yamnet_class_map.csv`, `assets/ml/swallow_classifier.tflite` 복사 + pubspec 등록
2. [ ] pubspec 의존성 5종 추가 후 `flutter pub get`
3. [ ] AndroidManifest 권한 3종 추가, minSdk 24 확인/상향
4. [ ] `lib/sensing/`에 6개 엔진 파일 복사 (import 경로만 조정)
5. [ ] `med_sensing_service.dart` 작성 — main.dart의 `_initModel`/`_onChunk`/`_startAccelerometer` 로직 이전
6. [ ] `ScheduleService`에 write 메서드 추가 — `setTaken()`(복약) + `setMeal()`(식사) + `addPendingMed()`
7. [ ] `med_phase_controller.dart` — 스케줄(`kind: meal`/`med`) 기반 P1/P2 창 제어
8. [ ] (식사 포함 시) `meal_state_machine.dart` — M_chew 지속/무음으로 inProgress/eaten 판정 → `setMeal` 연결
9. [ ] `main.dart` MultiProvider에 `MedSensingService` 등록, 권한 요청 흐름 연결
10. [ ] (결정사항 2에 따라) Gemini/TTS 재확인 경로 연결
11. [ ] 실기기 검증 (마이크 권한, 식사 eaten·복약 taken → Firestore 반영 확인)

---

## 6. 리스크

- **flutter_sound + minSdk**: 기존 알림/알람 기능과 충돌 없는지 빌드 확인 필요.
- **상시 마이크**: 배터리/프라이버시 — 캡스톤 발표 시 "왜 항상 듣고 있나" 지적 대비 (P2 창 한정 권장).
- **tflite 모델 2개 동시 로드** 메모리: 저사양 기기 확인.
- **swallow 신뢰도**: 주석상 아직 미확보 → 80점↑도 자동확정 안 하고 Gemini 안전망 전제. 그래서 결정사항 2가 중요.
</content>
</invoke>
