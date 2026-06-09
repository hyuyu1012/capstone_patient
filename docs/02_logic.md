# 로직별 — 감시 스케줄링 · 식사연동 · 알림

> 갱신: 2026-06-09 · 같이 보기: [개요](01_overview.md) · [AI 감지엔진](03_sensing_ai.md)
> 범위: "언제 무엇을 들을지 / 어느 약·식사로 칠지 / 어떻게 알릴지" 등 **룰베이스 결정 로직**.
> 소리에서 복약/식사를 *판정*하는 부분은 [AI 문서](03_sensing_ai.md)에 분리.

---

## 1. 감시 단계 컨트롤러 (`med_phase_controller.dart`)

스케줄 시간표를 보고 매 20초(`kTick`)마다 지금이 어느 단계인지 정하고 마이크를 켜고 끈다. `decideAt(now)`는 순수 함수라 단위 테스트 가능.

### 단계 우선순위 (gap 제거 후)
1. **P1 (식사)** — 완료 안 된 식사의 창 안이면 최우선. 이때 약 점수가 차도 트리거 안 함(식사 소음과 복약 구분 불가).
2. **P2 (복약)** — 활성 약 창이 있으면. 식후=식사완료 이벤트, 식전·식사무관=시계.
3. **idle** — 그 외. 마이크 OFF.

> [2026-06-09] **gap(공백기) 단계 제거.** 식사 직후 "어느 약인지 미정" 5분 창을 없앴다. (스코어러 enum엔 코드가 남아있으나 컨트롤러가 더 이상 진입시키지 않음 → `onUnknownMed`/`pendingMeds`는 휴면.)

### 창 상수 (현재값)
| 상수 | 값 | 의미 |
|---|---|---|
| `kPreMeal` | **0분** | P1은 식사 예정시간 **정각부터**(프리롤 제거). 식사 직전 식전약 창을 P1이 가리던 부작용 제거 |
| `kMealMaxDuration` | **90분** | 식사완료를 끝내 못 잡으면 식사 예정 +90분에 P1 닫힘(=식사 지연 허용 한계) |
| `kPreMed` | **0분** | 시계 약 창도 예정시간 정각부터(프리롤 제거) |
| `kPostMed` | **30분** | 식전·식사무관 약 창 길이 |
| `kPostMedAfter` | **40분** | 식후약 전용 창 길이(약통 꺼냄·물·삼킴까지 더 길게) |
| `kMealAssocMaxGap` | **2시간** | 식후약↔식사 시간추정 연결 시 이보다 먼 식사는 제외 |

---

## 2. 식전 / 식후 / 식사무관 분기 (`_medWindow`)

```
식후(after) + 이벤트ON →
   · 연결 식사가 "스킵됨"      → 약 time 기준 시계 창 [time, +40분] (식사 없이 진행)
   · 연결 식사 "완료 감지"     → [완료시각, +40분]
   · 그 외(미감지)            → 창 안 엶 (폴백 없음)
식전(before)          → [약 time, 연결 식사 시작 전까지] (식전 O분 = 그 구간; 식사 시작하면 닫힘)
                        · 연결 식사 없으면 [time, +30분] 시계 창으로 폴백
식사무관(none)        → 약 time 기준 시계 창 [time, +30분]
```

- **식후약만** 식사완료 이벤트에 연동된다. 식사무관은 절대시각 시계.
- **식전약**[2026-06-09]: 약 time부터 **연결 식사 시작 전까지** 감시(04 스펙 "식전 O분 → O분 동안"). `mealId`로 연결 식사를 찾고, 식사가 시작되면 창을 닫는다.
- `afterMedUsesMealEvent`는 `MedSensingService`(io)에서 **true**로 켜져 있다.
- **복용 확정 시 즉시 종료**[2026-06-09]: 스코어러 80점 트리거(p2) → 서비스가 `controller.notifyMedTaken(id)` 호출 → 그 약은 Firestore taken 왕복을 기다리지 않고 **로컬에서 즉시** 감시 대상에서 빠진다(04 스펙 "복용 완료되면 즉시 종료").

### 식후약 ↔ 식사 연결 (`_mealFor`)
1. 보호자 앱이 심은 **`mealId`가 있으면 그 식사로 정확히 연결**.
2. 없으면(구버전 데이터) **약 time 직전 가장 가까운 식사**로 시간추정(2시간 이내).

---

## 3. 식후약 = 식사완료 이벤트 — 설계 결정 (왜 폴백을 버렸나)

식후약 감시 창을 **약 예정시각(시계)** 대신 **실제 식사완료 감지 시점**에 연다.

### 동작 (예: 6:00 식사)
| 상황 | 결과 |
|---|---|
| 6:00~7:30 사이 식사완료 감지 | 완료 시점부터 **40분** 식후약 창 ✓ |
| 씹기는 잡혔으나 7:30까지 3분 무음 미충족 | 7:30(P1 종료)에 강제 eaten → 그때부터 창 ✓ |
| 7:30까지 씹기 자체 미감지(외식 등) | **식후약 창 안 열림**(폴백 없음) ✗ — 의도된 한계 |
| 보호자가 그 식사를 **건너뜀(skip)** | 약 **예정시간** 시계 창 40분으로 진행 ✓ (아래 §7-1) |

### 왜 시계 폴백을 포기했나
- 폴백 창(`[medTime, +40]`)은 식후약이 보통 식사+30분이라 90분 P1 창(`~식사+90`) 안에 통째로 들어가 **P1에 가려진다**(P1 > P2 우선). 즉 폴백이 필요한 "식사 미감지" 상황에서 오히려 작동 못 함.
- 모순을 안고 가느니 **폴백을 명시적으로 포기**하고, 식후약은 "식사완료가 실제 감지된 경우에만" 동작.
- 임의 지연(90분 초과)까지 잡으려면 "상시 청취"가 필요(배터리 직격)하므로 현 단계 범위 밖.

---

## 4. capstone_ui(보호자 앱) 연동

식후약 연동은 양쪽 앱이 함께 동작해야 성립한다.

### 보호자 앱이 하는 일
- 식사를 먼저 등록 → `meal` 항목(절대시각, doc id 부여).
- 약 등록 시 "복용 식사"(어느 식사) + "복용 시점"(식전/식후 + 분)을 고르면:
  - 알림용 절대시각 = `_addMinutes(meal.time, sign*offset)`로 계산해 `time`에 저장.
  - **`mealRelation`('before'/'after')과 `mealId`(연결 식사 doc id)를 함께 저장** ← [2026-06-09 추가]
- 파일: `capstone_ui/lib/data/schedule_service.dart`(addSchedule), `lib/screens/register_sheets.dart`.

### 환자 앱이 받는 것
- `ScheduleItem.fromMap`이 `mealRelation`/`mealId`를 읽어 컨트롤러로 전달.
- 식후약이면 `mealId`로 연결 식사를 찾고, 그 식사의 **완료 감지** 시점에 P2 창을 연다.

> 식전약은 양쪽 다 절대시각(시계)로만 처리 — 추가 필드 불필요. "식전 = 시간 기반"이 두 앱의 합의.

---

## 5. 식사 완료 판정 (`meal_state_machine.dart`)

P1 단계에서 씹는 소리(M_chew)의 흐름만 보고 식사 상태를 만든다.

| 상수 | 값 | 의미 |
|---|---|---|
| `kMinChews` | **4** | 씹기 4회 이상 → "식사 중"(inProgress) [2026-06-09, 04 스펙: 3→4] |
| `kSilenceToEaten` | 3분 | 마지막 씹기 후 3분 무음 → "완료"(eaten) |

- 또는 P1 창이 닫힐 때 "식사 중"이었으면 `finalizeOnExit()`로 강제 완료(3분 무음 못 채운 안전망).
- 완료되면 그 식사 id로 `notifyMealCompleted` → 식후약 P2 창 트리거 + Firestore `setMeal`.

---

## 6. 결과 쓰기 (`schedule_service.dart`)

| 상황 | 콜백 | Firestore |
|---|---|---|
| P2에서 80점 | `onMedConfirmed` → `setTaken` | `taken=true, takenAt, detectStatus='confirmed', detectedBy='sensor_p2'` |
| 식사 완료 | `onMealEaten` → `setMeal` | `mealStatus='eaten', taken=true, takenAt` |
| (휴면) gap 80점 | `onUnknownMed` → `addPendingMed` | gap 제거로 현재 미발생 |

UI는 기존 `taken(bool)`만 읽어도 동작(센서 추가 필드는 무시 가능).

---

## 7. 스킵(건너뜀) — 보호자 전용

- **설정은 보호자 앱(`capstone_ui`)에서만**: 토글 버튼 + `setSkipped` 쓰기.
- **환자 앱은 읽기만**: 설정 경로 없음. `skipped` 항목을 **알림 대상에서 제외**하고 "건너뜀"으로 표시.
- **감지 엔진엔 스킵 포함 전체 목록을 전달**(`schedule_screen`)한다. 컨트롤러가 직접 스킵을 보고:
  - 스킵된 식사 → P1 감시 안 함 / 스킵된 약 → P2 감시 안 함.
  - 스킵된 식사에 묶인 **식후약**은 아래 규칙으로 진행.

### 7-1. 식사 스킵 → 식후약 시계 창 [2026-06-09]

연결된 식사를 보호자가 **건너뜀**으로 표시하면 = "오늘 이 끼니는 없다"는 명시적 신호.
→ 식후약은 **식사 감지를 기다리지 않고** 약 예정시간 시계 창 `[time, +kPostMedAfter(40분)]`으로 진행한다.

- 스킵된 식사는 P1을 안 여므로, 폴백을 막던 "90분 P1 그림자" 문제(§3)가 이 경우엔 없다 → 시계 창이 가려지지 않는다.
- 즉 폴백을 전면 포기하되, **"스킵"이라는 명시 신호가 있을 때만** 시계 창을 되살린다.
- 보호자 앱은 식사를 새로 건너뜀으로 바꿀 때, 묶인 미완료 식후약이 있으면 SnackBar로 안내한다(`home_screen` `_skipWithHint`).

---

## 8. 음성 알림 / TTS (`notification_service.dart`, `tts_service.dart`)

- 일정 1건당 **매일 같은 시각 반복 로컬 알림**(`zonedSchedule` + `matchDateTimeComponents.time`).
- 채널 사운드로 사전 녹음 음성(`med_voice`/`meal_voice`) 재생 → 앱이 꺼져도 음성 알림.
- `fullScreenIntent` + `alarmClock` 모드 → 잠금화면 위로 알람처럼 깨움.
- 앱이 알림으로 깨어나면(`launchReminder`/`dueItemAround`) **TTS로 실제 일정 낭독**.
- `syncSchedules`는 시그니처 비교로 변경 없으면 no-op(재등록 폭주 방지).

### 8-1. 음성 클립 파일 (운영 메모)
- 코드가 파일명을 참조하므로 **정확히 일치**해야 함. 없으면 OS 기본 알림음으로 대체(동작은 정상).
- **Android** (`android/app/src/main/res/raw/`, 확장자 없이 참조 / 소문자·숫자·`_`만):
  `med_voice.wav`("약 드실 시간이에요"), `meal_voice.wav`("식사 시간이에요"). 지원: mp3/wav/ogg.
- **iOS** (`ios/Runner/med_voice.aiff`, `meal_voice.aiff`): Xcode → Runner → Build Phases → **Copy Bundle Resources에 추가해야** 재생됨. iOS는 앱 자동실행 불가 → 고정 음성만, 이름 낭독 못 함.
- **Android 14+**: `USE_FULL_SCREEN_INTENT` 기본 거부 가능 → 최초 1회 허용 또는 헤드업 알림으로 대체. 제조사 배터리 최적화 제외 권장.
- 기본 한국어 클립은 macOS `say -v Yuna`로 합성된 것이 포함돼 있음(같은 파일명으로 교체 가능).

---

## 9. "진행중…" 표시 (04 스펙) [2026-06-09]

감지 엔진이 **지금 감시 중인 항목**(P1 식사 / P2 약)을 UI에 "진행중…"으로 보여준다.

- **상태 전달**: 서비스 isolate가 `onState`마다 `sendDataToMain({'type':'state', 'phase', 'targetId', ...})` → 메인의 `SensingForegroundController.onData`가 받아 `activeTargetId`(`ValueNotifier<String?>`)를 갱신(idle이면 null).
- **환자 앱 UI**: `schedule_screen`의 타일이 `activeTargetId`를 `ValueListenableBuilder`로 구독 → `item.id == activeTargetId`이고 완료/건너뜀이 아니면 "● 진행중…" 표시. (값이 바뀔 때만 해당 타일만 갱신)
- **보호자 앱**: **미구현(보류)**. 보호자는 Firestore만 보므로, 표시하려면 환자 앱이 live 감시상태(`monitoring` 필드 등)를 Firestore에 써야 함 — 단계 전환마다 쓰기가 늘어 별도 결정 후 진행.

---

## 한계 요약

> 식후약은 "식사가 감지되어야" 잡힌다. 외식·국물식사처럼 씹기가 안 잡히면 식후약 미포착(폴백 포기). 식사 지연 허용 한계 = `kMealMaxDuration`(90분).
> **예외**: 보호자가 그 식사를 *건너뜀*으로 표시하면, 식후약은 예정시간 시계 창으로 진행한다(§7-1).
