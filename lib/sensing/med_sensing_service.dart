// ─────────────────────────────────────────────────────────────
// med_sensing_service.dart  — 플랫폼별 구현 선택 facade
//
// YAMNet 감지 엔진은 tflite_flutter(dart:ffi)에 의존해 웹에서 컴파일이 안 된다.
// 따라서 조건부 export로:
//   - 네이티브(dart:io 사용 가능) → med_sensing_service_io.dart (진짜 엔진)
//   - 웹                          → med_sensing_service_stub.dart (no-op)
// 둘은 동일한 public API(MedSensingService)를 노출하므로, 앱 코드는 플랫폼을
// 신경 쓰지 않고 이 파일만 import하면 된다.
// ─────────────────────────────────────────────────────────────

export 'med_sensing_state.dart';
export 'med_sensing_service_stub.dart'
    if (dart.library.io) 'med_sensing_service_io.dart';
