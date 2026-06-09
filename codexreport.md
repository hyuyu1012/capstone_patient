# capstone_patient 코드 분석 보고서

> 작성일: 2026-06-09  
> 작성 범위: `lib/`, `test/`, 관련 `docs/` 문서  
> 작성 기준: 현재 저장소의 실제 코드 동작 기준. 코드 수정 없이 분석만 수행했다.

## 1. 한 줄 요약

이 앱은 보호자 앱이 Firestore에 등록한 약과 식사 일정을 환자 앱에서 실시간으로 받아 보여주고, 로컬 음성 알림과 TTS로 알려주며, Android/iOS 네이티브 환경에서는 foreground service 안에서 마이크, YAMNet, 삼킴 CNN, IIR, 가속도계를 사용해 식사 완료와 복약 정황을 감지한 뒤 Firestore에 다시 기록하는 환자용 앱이다.

핵심 감지 흐름은 다음과 같다.

```text
Firestore 일정
  -> ScheduleScreen
  -> 알림 동기화 + 감지 엔진에 일정 전달
  -> MedPhaseController가 P1/gap/P2/idle 결정
  -> MedSensingService가 마이크/센서 처리
  -> MedicationScorer가 120초 점수합 80점 이상 판단
  -> ScheduleService가 Firestore에 결과 기록
```

## 2. 주요 파일 역할

| 파일 | 역할 |
|---|---|
| `lib/main.dart` | Firebase 초기화, Provider 구성, 알림으로 앱이 열린 경우 TTS 재생, 인증/claim 상태에 따른 화면 라우팅 |
| `lib/screens/schedule_screen.dart` | 환자 일정 실시간 표시, skipped 제외 후 알림과 감지 엔진에 active 일정 전달 |
| `lib/models/schedule_item.dart` | 일정 모델. `kind`는 `med/meal`, `mealRelation`은 `before/after/none` |
| `lib/data/notification_service.dart` | 약/식사 로컬 알림 등록, 사전 녹음 음성 알림 채널, 알림 payload 처리 |
| `lib/data/tts_service.dart` | 알림으로 앱이 열렸을 때 실제 약/식사 이름을 한국어 TTS로 읽음 |
| `lib/sensing/med_phase_controller.dart` | 현재 시간이 식사(P1), 복약(P2), 공백기(gap), 대기(idle) 중 어디인지 결정 |
| `lib/sensing/med_sensing_service_io.dart` | 네이티브 감지 엔진 배선. 마이크 청크, YAMNet, 삼킴 CNN, IIR, 가속도계를 scorer에 전달 |
| `lib/sensing/meal_state_machine.dart` | P1 중 씹기 흐름으로 식사 중/식사 완료 판단 |
| `lib/sensing/medication_scorer.dart` | 복약 점수 계산, 80점 이상 트리거, 음식/설거지 오탐 차단 |
| `lib/sensing/sensing_foreground_controller.dart` | UI isolate에서 foreground service 시작/종료, 일정 push, 감지 결과 Firestore 쓰기 연결 |
| `lib/sensing/sensing_task_handler.dart` | foreground service isolate 진입점. 실제 감지 엔진 실행 |
| `lib/data/schedule_service.dart` | Firestore 일정 읽기, 복약 확정/식사 완료/미정 복약 기록 |

## 3. 앱 전체 흐름

1. `main.dart`에서 Firebase, 알림, TTS를 초기화한다.
2. 사용자가 로그인하면 `AuthGate`가 환자 claim 여부를 확인한다.
3. claim 완료 후 `MedSensingBinder`가 감지 foreground service를 시작한다.
4. `ScheduleScreen`은 `patients/{patientId}/schedules`를 실시간 구독한다.
5. 화면에 표시할 때 skipped 항목은 목록에는 보이지만 알림과 감지 대상에서는 제외된다.
6. active 일정은 두 곳으로 전달된다.
   - `NotificationService.syncSchedules(active)`: 매일 반복 알림 등록
   - `SensingForegroundController.pushSchedule(active)`: 감지 엔진에 오늘 일정 전달
7. 감지 결과는 service isolate에서 main isolate로 넘어오고, `ScheduleService`가 Firestore에 기록한다.

## 4. 일정 데이터 모델

`ScheduleItem`은 약과 식사를 하나의 모델로 다룬다.

| 필드 | 의미 |
|---|---|
| `id` | Firestore 문서 id |
| `kind` | `med` 또는 `meal` |
| `name` | 약 이름 또는 식사 이름 |
| `time` | `"HH:mm"` 형식 예정 시각 |
| `dose` | 약 복용량. 식사는 보통 null |
| `taken` | UI 호환 완료 여부 |
| `takenAt` | 완료 시각 `"HH:mm"` |
| `skipped` | 보호자가 오늘 의도적으로 건너뛴 일정 |
| `mealRelation` | 약의 식사 관계. `before`, `after`, `none` |

`mealRelation`은 감지 창을 여는 기준이다.

| 값 | 현재 구현 |
|---|---|
| `before` | 약 예정시간 기준 시계 창으로 P2를 연다 |
| `after` | 식사 완료 이벤트가 발생한 경우에만 P2를 연다 |
| `none` | 약 예정시간 기준 시계 창으로 P2를 연다 |

주의할 점은 `ScheduleItem` 주석에는 식전약을 "식사 예정시간 기준"처럼 설명하는 흔적이 있지만, 실제 `MedPhaseController` 구현은 식전약도 `med.time` 기준으로 처리한다.

## 5. 음성 알림과 TTS

현재 음성 기능은 두 층이다.

1. 로컬 알림 사운드
   - 약: `med_voice`
   - 식사: `meal_voice`
   - Android는 알림 채널 사운드, iOS는 notification sound로 처리한다.

2. 앱이 알림으로 열렸을 때 TTS
   - `TtsService.speakItem()`이 실제 일정명을 읽는다.
   - 예: `오메가3, 1정 드실 시간이에요`
   - 식사 예: `식사 시간이에요. 아침 드세요`

중요한 한계가 있다. 현재 코드는 복약 점수 80점 이상일 때 환자에게 TTS로 "약 드셨나요?"라고 묻고 답을 받는 기능을 구현하지 않는다. 코드상 트리거 이름은 `geminiVerify`지만, 실제 Gemini 호출, STT, 환자 응답 수집, TTS 재확인 흐름은 없다.

## 6. 감지 단계 구조

감지 단계는 `MedPhase`로 구분된다.

| 단계 | 의미 | 마이크 | 복약 트리거 |
|---|---|---:|---|
| `idle` | 감시 대상 일정 없음 | OFF | 없음 |
| `p1` | 식사 감시 | ON | 발생하지 않음 |
| `gap` | 식사 완료 직후, 특정 약을 겨냥하지 않는 공백기 | ON | 80점 이상이면 미정 복약 |
| `p2` | 복약 감시 | ON | 80점 이상이면 해당 약 복약 확정 |

`MedPhaseController.decideAt()`의 우선순위는 다음 순서다.

```text
1. P1 식사 창
2. P2 복약 창
3. gap 공백기
4. idle 대기
```

따라서 식사 창이 아직 끝나지 않은 상태에서는 약 시간이 와도 P1이 우선한다. 이 설계는 식사 중 물소리와 삼킴 소리를 복약으로 오인하지 않기 위한 것이다.

## 7. 단계 시간 상수

| 상수 | 값 | 의미 |
|---|---:|---|
| `kPreMeal` | 0분 | 식사 P1은 식사 예정 정각부터 시작 |
| `kMealMaxDuration` | 90분 | 식사 완료가 감지되지 않아도 P1을 유지하는 최대 시간 |
| `kPreMed` | 10분 | 시계 기반 약 창은 약 예정시간 10분 전부터 시작 |
| `kPostMed` | 30분 | 식전/식사무관 약의 시계 기반 약 창 길이 |
| `kPostMedAfter` | 40분 | 식후약 전용 이벤트 기반 약 창 길이 |
| `kMealAssocMaxGap` | 2시간 | 식후약과 연결할 이전 식사의 최대 간격 |
| `kGapDuration` | 5분 | 식사 완료 후 특정 약 창이 없을 때 유지하는 공백기 |
| `kTick` | 20초 | phase 재평가 주기 |

## 8. 식전약 트리거

식전약은 `mealRelation == before`인 약이다.

현재 구현 기준 식전약은 식사 완료 이벤트를 기다리지 않는다. `MedPhaseController._medWindow()`에서 식전약은 식사무관 약과 같이 `med.time` 기준 시계 창으로 처리된다.

```text
식전약 P2 창 = [약 예정시간 - 10분, 약 예정시간 + 30분)
```

식전약 동작 순서는 다음과 같다.

```text
보호자 앱이 before 약 일정 등록
  -> 환자 앱 ScheduleScreen이 일정 수신
  -> foreground service에 일정 push
  -> 현재 시간이 [med.time -10분, med.time +30분) 안이면 P2
  -> 마이크 ON
  -> 복약 점수 80점 이상
  -> onMedConfirmed(scheduleId, at)
  -> schedules/{id}.taken=true, takenAt 기록
```

주의할 점은 다음과 같다.

- P1 식사 창이 이미 열려 있으면 P1이 P2보다 우선한다.
- `kPreMeal`이 0분이라 식사 예정시간 전에는 P1이 열리지 않는다. 그래서 식사 직전 식전약 창이 과거보다 덜 가려진다.
- 계획 문서에 있는 "종료 5분 전 재안내", "30분 후 미복용 처리"는 현재 코드에 구현되어 있지 않다.

## 9. 식사 트리거

식사는 `kind == meal`인 일정으로 처리된다. 식사 예정시간이 되면 P1 창이 열린다.

```text
식사 P1 창 = [식사 예정시간, 식사 예정시간 + 90분)
```

P1 중에는 마이크가 켜지고, YAMNet의 chewing score가 식사 상태머신으로 전달된다.

식사 완료 판단 규칙은 `MealStateMachine`에 있다.

| 조건 | 결과 |
|---|---|
| 씹기 감지 3회 미만 | `notEaten` 유지 |
| 씹기 감지 3회 이상 | `inProgress` |
| `inProgress` 상태에서 마지막 씹기 후 3분 무음 | `eaten` |
| P1 창이 닫힐 때 아직 `inProgress` | `finalizeOnExit()`로 `eaten` 처리 |

식사 완료 트리거 흐름은 다음과 같다.

```text
P1 진입
  -> _meal.reset()
  -> 마이크 청크마다 chewing 여부 계산
  -> chewing이면 _meal.onChew(now)
  -> _meal.tick(now)가 true
  -> _onMealEaten(mealId, now)
  -> controller.notifyMealCompleted(mealId, now)
  -> onMealEaten(mealId, now)
  -> schedules/{mealId}.mealStatus='eaten', taken=true, takenAt 기록
```

P1 단계에서는 복약 점수가 쌓일 수는 있지만 복약 트리거는 발생하지 않는다. 즉 식사 중 삼킴과 물소리를 복약으로 확정하지 않는다.

## 10. 식후약 트리거

식후약은 `mealRelation == after`인 약이다. 현재 네이티브 감지 서비스는 `afterMedUsesMealEvent: true`로 컨트롤러를 생성한다.

따라서 식후약은 약 예정시간만으로 P2를 열지 않고, 연결된 식사의 완료 이벤트가 있어야 한다.

연결 식사는 `_mealFor()`가 찾는다.

```text
약 예정시간 이전에 있는 식사 중
약 예정시간과 2시간 이내이고
가장 가까운 식사
```

식후약 창은 다음과 같다.

```text
식후약 P2 창 = [연결 식사 완료시각, 완료시각 + 40분)
```

식후약 동작 순서는 다음과 같다.

```text
식사 P1에서 식사 완료 감지
  -> notifyMealCompleted(mealId, completedAt)
  -> 연결된 after 약이 있으면 P2 창 열림
  -> 마이크 ON
  -> 복약 점수 80점 이상
  -> onMedConfirmed(scheduleId, at)
  -> schedules/{afterMedId}.taken=true, takenAt 기록
```

현재 구현의 핵심은 "폴백 없음"이다.

- 식사를 끝내 감지하지 못하면 식후약 P2 창은 열리지 않는다.
- `med_phase_controller.dart` 상단과 일부 주석에는 시계 폴백 설명이 남아 있지만, 실제 `_medWindow()` 구현은 `afterMedUsesMealEvent == true`이고 식사 완료 기록이 없으면 `null`을 반환한다.
- `test/med_phase_controller_test.dart`도 "식사 미감지면 식후약 시계 창을 열지 않는다"를 테스트한다.

## 11. gap 트리거

`gap`은 식사 완료 직후 5분 동안 유지되는 공백기다. 단, 우선순위상 P2 식후약 창이 열릴 수 있으면 P2가 먼저 선택된다.

gap의 의미는 "복약 정황은 있는데 어느 약인지 특정하기 어렵다"이다.

```text
식사 완료
  -> 연결된 약 P2 창이 없음
  -> 5분 이내 gap
  -> 복약 점수 80점 이상
  -> onUnknownMed(score, at)
  -> patients/{patientId}/pendingMeds에 unknown 이벤트 추가
```

Firestore에는 다음 형태로 기록된다.

```text
detectStatus = 'unknown'
detectedBy = 'sensor_gap'
takenAt = HH:mm
score = 감지 당시 점수
needsGemini = true
```

하지만 실제 Gemini 확인 플로우는 아직 없다. 현재는 pending 큐에 쌓는 것까지만 구현되어 있다.

## 12. 복약 점수 계산

복약 점수는 `MedicationScorer`가 120초 윈도우 안에서 카테고리별 최초 1회만 누적한다.

| 카테고리 | 점수 | 입력 |
|---|---:|---|
| `water` | 20 | YAMNet 물 계열. 물은 confidence 0.12 이상 |
| `package` | 20 | YAMNet 약통/약봉지 계열. confidence 0.3 이상 |
| `swallow` | 30 | 삼킴 CNN 점수와 IIR 감지가 같은 청크에서 모두 감지 |
| `stationary` | 20 | 가속도계 5초 윈도우에서 정지 비율 60% 이상 |
| `etc` | 10 | 목 가다듬기, 클릭 등 |

트리거 기준은 다음 하나다.

```text
현재 점수합 >= 80
```

트리거 타입은 항상 `MedTriggerType.geminiVerify`다. 이름은 Gemini 검증이지만, 실제 처리에서는 phase만 보고 분기한다.

| phase | 80점 이상 시 실제 처리 |
|---|---|
| `p2` | 현재 P2 대상 scheduleId를 복약 확정 |
| `gap` | 어느 약인지 미정으로 pendingMeds 기록 |
| `p1` | 트리거 없음 |
| `idle` | 트리거 없음 |

## 13. 오탐 차단 로직

복약 감지는 gap과 p2에서만 트리거된다. 이때 다음 차단 로직이 적용된다.

| 차단 | 조건 | 해제 |
|---|---|---|
| `foodConflict` | 최근 30초 내 씹기 4회 이상 | 마지막 씹기 후 15초 |
| `dishwashing` | Glass와 Dishes/pots가 5초 이내 함께 감지 | 최근 설거지 신호 후 15초 |

P1에서는 복약 트리거 자체가 발생하지 않으므로 차단보다 phase 정책이 먼저 동작한다.

## 14. Firestore 기록 방식

`ScheduleService`가 결과를 Firestore에 기록한다.

| 상황 | 메서드 | 기록 |
|---|---|---|
| P2 복약 확정 | `setTaken()` | `taken=true`, `takenAt`, `detectStatus='confirmed'`, `detectedBy='sensor_p2'` |
| P1 식사 완료 | `setMeal()` | `mealStatus='eaten'`, `taken=true`, `takenAt` |
| gap 미정 복약 | `addPendingMed()` | `pendingMeds` 하위 컬렉션에 `unknown`, `score`, `needsGemini=true` |

기존 UI가 `taken(bool)`만 읽어도 깨지지 않게 설계되어 있고, 센서 세부 상태는 `detectStatus`, `mealStatus`, `detectedBy` 같은 보조 필드로 추가된다.

## 15. 플랫폼별 동작

| 플랫폼 | 동작 |
|---|---|
| Android | 감지 엔진, foreground service, 마이크, 알림, TTS 동작 대상 |
| iOS | 알림/TTS 배선은 있으나 TFLite/foreground 감지는 실기기 검증 필요 |
| Web | 감지 엔진은 stub no-op. UI, Firebase, 스케줄 표시만 동작 |

웹은 `tflite_flutter`, `flutter_sound`, foreground service 제약 때문에 감지가 비활성이다.

## 16. 테스트로 확인된 부분

`test/med_phase_controller_test.dart`와 `test/meal_state_machine_test.dart`에서 순수 로직 일부가 검증되어 있다.

확인된 내용은 다음과 같다.

- 식사 P1은 식사 예정 정각부터 시작한다.
- 식사 정각 전에는 P1이 아니다.
- 식사 미완료 상태에서는 약 시간이 와도 P1이 우선한다.
- 식후약은 식사 완료 시점부터 40분간 P2가 된다.
- 식사 미감지 시 식후약 시계 폴백은 열리지 않는다.
- 식사무관 약은 약 시간 기준 시계 창으로 P2가 된다.
- 식사 완료 직후 뒤따르는 약이 없으면 gap이 된다.
- taken=true 약은 P2 대상에서 제외된다.
- 식사 상태머신은 씹기 3회 이상, 3분 무음, P1 종료 시 finalize 동작을 검증한다.

## 17. 현재 코드 기준 리스크와 미구현 사항

1. 80점 이상 후 환자에게 묻는 TTS/STT 재확인 없음
   - `geminiVerify`라는 이름은 있지만 실제 Gemini, TTS 질문, STT 답변 수집은 없다.
   - p2에서는 센서 점수만으로 곧바로 `taken=true`가 된다.

2. 식전약 재안내와 미복용 처리 없음
   - 계획 문서에는 종료 5분 전 재안내와 30분 후 미복용 처리가 있으나 현재 구현에는 없다.

3. 식후약은 식사 미감지 시 잡지 못함
   - 현재 정책상 폴백을 포기했기 때문에, 외식이나 씹기 소리가 약한 식사처럼 P1이 eaten을 못 만들면 식후약 P2가 열리지 않는다.

4. `mealRelation` 입력 의존
   - 보호자 앱이 `mealRelation='after'` 또는 `'before'`를 정확히 써줘야 이 분기가 의미를 가진다.
   - 값이 없거나 알 수 없으면 `none`으로 파싱되어 단순 시계 기반 약이 된다.

5. 주석과 실제 구현이 일부 불일치
   - 일부 주석은 식후약 시계 폴백을 설명하지만 실제 코드는 폴백 없음이다.
   - `ScheduleItem`의 식전 설명도 실제 controller 기준과 다르게 읽힐 수 있다.

6. `orderValid`는 계산되지만 트리거를 막지 않는다
   - swallow가 package/water 뒤에 왔는지 계산하지만, 80점 이상이면 `orderValid=false`여도 트리거가 발생한다.

7. 실기기 검증 필요
   - service isolate에서 `flutter_sound`, TFLite, 마이크 권한 요청, 백그라운드 생존이 실제 폰에서 안정적인지 확인이 필요하다.

## 18. 식전약/식사/식후약 트리거 요약

| 구분 | 창을 여는 조건 | 감지 조건 | 결과 |
|---|---|---|---|
| 식전약 | `mealRelation=before`, 현재 시간이 `[med.time-10분, med.time+30분)` | P2에서 복약 점수 80점 이상 | 해당 약 `taken=true` |
| 식사 | `kind=meal`, 현재 시간이 `[meal.time, meal.time+90분)` | 씹기 3회 이상 후 3분 무음 또는 P1 종료 시 finalize | 해당 식사 `mealStatus=eaten`, `taken=true` |
| 식후약 | `mealRelation=after`, 연결 식사 완료 이벤트 발생 | 완료 시각부터 40분 안 P2에서 복약 점수 80점 이상 | 해당 식후약 `taken=true` |
| gap | 식사 완료 후 5분, 겨냥할 약 P2가 없음 | gap에서 복약 점수 80점 이상 | `pendingMeds`에 unknown 기록 |

## 19. 결론

현재 앱은 일정 수신, 음성 알림, TTS, foreground service 기반 감지, Firestore 결과 기록까지 큰 흐름은 갖춰져 있다. 식전약은 약 시간 기준 P2, 식사는 P1에서 씹기 기반 완료, 식후약은 식사 완료 이벤트 기반 P2로 분기된다.

다만 "80점 이상이면 환자에게 TTS로 물어보고 확인한다"는 흐름은 아직 구현되어 있지 않다. 현재 p2에서는 센서 점수 80점만으로 복약 확정이 되며, gap에서는 pendingMeds에 미정 이벤트를 쌓는다. 또한 식후약은 식사 완료 감지가 실패하면 창 자체가 열리지 않는 구조이므로, 이 부분은 데모와 보고서에서 명확히 설명해야 한다.
