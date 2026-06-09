# 개요 — capstone_patient (환자 앱)

> 작성/갱신: 2026-06-09 · 대상: `lib/` 전체
> 같이 보기: [로직별](02_logic.md) · [AI 감지엔진](03_sensing_ai.md)

---

## 한 줄 요약

**보호자 앱(`capstone_ui`)이 등록한 약·식사 일정을 환자 폰이 실시간으로 받아 ① 음성 알림으로 알려주고 ② 마이크·가속도계로 복약/식사를 자동 감지해 Firestore에 다시 써주는** 환자 전용 동반 앱. 두 앱은 같은 Firebase 프로젝트(`capstone-2b4a9`)를 공유한다.

---

## 두 앱의 관계

```
[capstone_ui — 보호자 앱]                 [capstone_patient — 환자 앱(이 repo)]
  약·식사 일정 등록(식전/식후 포함)            일정 실시간 구독 → 음성 알림 + 자동 감지
        │  쓰기                                      ▲ 읽기        │ 감지 결과 쓰기
        ▼                                            │             ▼
        └────────────  Firestore: patients/{id}/schedules  ────────┘
```

- 보호자가 `patients/{id}` 문서(+`inviteCode`)와 그 아래 `schedules`를 만든다.
- 환자는 초대 코드로 그 문서를 **claim**(자기 `userId` 도장)하고 일정을 읽는다.
- 감지 결과(`taken`/`mealStatus` 등)는 같은 `schedules` 문서에 환자 앱이 되써, 보호자 앱이 본다.

---

## 화면 흐름 (`main.dart` AuthGate)

```
로그인(이메일/Firebase Auth)
   └ 미claim → 초대코드 입력(ClaimScreen)
        └ claim 완료 → MedSensingBinder(child: ScheduleScreen)  ← 일정 화면 + 감지 엔진 동시 기동
```

- 로그아웃 상태 → `LoginScreen`
- 로그인했지만 미claim → `ClaimScreen`
- claim 완료 → 일정 화면 + 감지 엔진(foreground service)

---

## 기능 모듈 (요약)

| 모듈 | 파일 | 한 줄 |
|---|---|---|
| 인증·환자 연결 | `data/auth_service`, `data/patient_link_service` | 이메일 로그인 + 초대코드 claim |
| 일정 표시 | `screens/schedule_screen` | `schedules` 실시간 구독, 완료/건너뜀 표시 |
| 음성 알림·TTS | `data/notification_service`, `data/tts_service` | 매일 반복 알림(음성 클립) + 앱 깨어나면 TTS 낭독 |
| 감지 엔진 | `lib/sensing/` | YAMNet/CNN/IIR + 점수 엔진으로 복약/식사 자동 감지 → [AI 문서](03_sensing_ai.md) |
| 감시 스케줄링 | `sensing/med_phase_controller` | 언제 어느 약/식사를 들을지(P1/P2) → [로직 문서](02_logic.md) |

---

## Firestore 데이터 계약 (`patients/{id}/schedules/{sid}`)

| 필드 | 쓰는 쪽 | 의미 |
|---|---|---|
| `kind` | 보호자 | `med` / `meal` |
| `name`, `dose`, `time` | 보호자 | 이름 / 용량 / "HH:mm"(절대시각) |
| `days` | 보호자 | 요일(반복) |
| `mealRelation` | 보호자 | `before`/`after` — 식전/식후. **식후약 감지 연동의 키** |
| `mealId` | 보호자 | 식후약이 연결된 식사의 doc id (정확 연결용) |
| `taken`, `takenAt` | 보호자/감지 | 복용 완료 + 시각 |
| `skipped` | **보호자만** | 오늘 건너뜀(환자 앱은 읽기만) |
| `mealStatus`, `detectStatus`, `detectedBy` | 감지 | 식사 완료 / 감지 출처 메타 |

- `mealRelation`/`mealId`는 [2026-06-09] 추가. 식후약을 "식사완료 감지" 시점에 잡기 위한 연동 필드 → [로직 문서](02_logic.md) 참고.
- `patients/{id}/pendingMeds`: 과거 gap(공백기) 감지가 쓰던 "어느 약인지 미정" 큐. **현재 gap 단계 제거로 휴면**(배선만 유지).

---

## 플랫폼 현황

- **Android**: 감지 포함 전체 동작 대상(foreground service 마이크 + 로컬 알림 + TTS).
- **iOS**: 알림/TTS 배선됨, 감지(tflite)는 미검증.
- **Web**: tflite(dart:ffi)·foreground service 미지원 → **감지 전부 no-op**(stub). UI/Firebase/스케줄만 동작.

---

## 미완 / 리스크 (앱 전체)

1. **2차 확인(Gemini) 미구현** — 센서 80점만으로 `taken=true` 확정. → [AI 문서](03_sensing_ai.md) 참고.
2. **실기기 미검증** — 빌드·단위테스트까지. 실제 마이크 감지 정확도/권한/백그라운드 생존 미확인.
3. **식사 미감지 시 식후약 미포착** — 폴백을 의도적으로 포기(설계 트레이드오프). → [로직 문서](02_logic.md).
4. **웹 감지 비활성** — 데모를 크롬에서 하면 감지 0.

---

## 결론

보호자가 등록한 일정을 환자 폰이 실시간으로 받아 **음성 알림 + 자동 복약/식사 감지**를 수행하는 동반 앱. 감시 *시점*은 스케줄 로직([logic](02_logic.md))이, 복약/식사 *판정*은 음향 AI 엔진([sensing_ai](03_sensing_ai.md))이 담당한다.
