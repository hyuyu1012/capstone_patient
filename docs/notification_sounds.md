# 음성 알림 동작 방식

예약 시각이 되면:
1. **알림이 화면을 깨우고 앱을 자동 실행**합니다 (잠금화면 위에도 — 알람 시계 방식,
   Android 풀스크린 인텐트). → `notification_service.dart`의 `fullScreenIntent: true`
2. 고정 음성 클립(아래)이 먼저 재생되고,
3. 앱이 켜지면서 **TTS가 실제 약·식사 이름을 읽습니다** (예: "오메가3, 한 정 드실
   시간이에요"). → `tts_service.dart`, `main.dart`의 cold-start/`_ReminderSpeaker`

## Android 자동 실행 관련 주의 (중요)
- **Android 14+**: 일반 앱은 `USE_FULL_SCREEN_INTENT` 권한이 기본 거부될 수 있어요.
  최초 1회 설정에서 허용하거나, 안 되면 상단 헤드업 알림으로 표시됩니다(탭하면 읽음).
- **제조사 배터리 최적화**(삼성·샤오미 등): 설정에서 이 앱을 "최적화 제외 / 자동 실행
  허용"으로 두면 정확한 시각에 더 안정적으로 깨어납니다.
- **iOS**: 앱 자동 실행은 OS가 금지합니다. iOS에서는 고정 음성 알림만 재생되며 이름은
  읽지 못합니다(플랫폼 한계).

---

# 음성 알림 사운드 파일

복용·식사 예약 알림은 **알림 채널의 사운드**로 음성 클립을 재생합니다. 파일명은
코드(`notification_service.dart`)에서 참조하므로 정확히 일치해야 합니다.

> 기본 한국어 음성 클립(macOS `say -v Yuna`로 합성)이 이미 포함되어 있습니다.
> 다른 목소리/멘트로 바꾸려면 같은 파일명으로 교체하세요.

## Android — 완료됨 ✅
`android/app/src/main/res/raw/` (확장자 없이 참조됨)

- `med_voice.wav`  → "약 드실 시간이에요"
- `meal_voice.wav` → "식사 시간이에요"

지원 포맷: `.mp3`, `.wav`, `.ogg`. 파일명은 **소문자·숫자·`_`** 만 사용 (대문자/하이픈 불가).

## iOS — 파일은 생성됨, Xcode 등록 필요 ⚠️
`ios/Runner/med_voice.aiff`, `ios/Runner/meal_voice.aiff` 가 생성되어 있습니다.
Xcode에서 **Runner 타깃의 번들 리소스에 추가**해야 실제로 재생됩니다:
Xcode → Runner 프로젝트 → Build Phases → Copy Bundle Resources → `+` 로 두 파일 추가.

## 파일이 없을 때
앱은 정상 동작하며 OS 기본 알림음으로 대체됩니다. 음성을 들으려면 위 파일을 반드시 추가하세요.

## 음성 파일은 어떻게 만드나
- 직접 녹음하거나
- TTS로 합성: macOS `say "약 드실 시간이에요" -o med_voice.aiff` 후 mp3로 변환
  (`ffmpeg -i med_voice.aiff med_voice.mp3`).
