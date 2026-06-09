import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

/// 마이크에서 16kHz mono PCM Int16 스트림을 받아
/// YAMNet 입력 길이(15600 샘플)만큼 모아서 콜백으로 넘겨주는 클래스.
///
/// flutter_sound 9.28+ 에서는 toStream 파라미터가
/// StreamSink<Uint8List> 형태로 바뀌었습니다.
class AudioStreamer {
  static const int sampleRate = 16000;
  static const int chunkSize = 15600; // YAMNet 0.975초

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _pcmController;
  StreamSubscription<Uint8List>? _sub;

  // 누적 버퍼 (Float32로 변환된 샘플)
  final List<double> _buffer = [];

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// openRecorder()가 완료됐는지. 서비스 isolate는 메인의 레코더를 물려받지 못하므로
  /// init()을 못 거친 경로로 start()가 와도 녹음 전 한 번은 열리도록 가드한다.
  bool _isOpen = false;

  /// 청크가 모일 때마다 호출되는 콜백
  void Function(Float32List chunk)? onChunk;

  Future<void> init() async {
    await _ensureOpen();
  }

  /// 레코더가 열려 있지 않으면 연다(한 번만). init()과 start() 양쪽에서 안전하게
  /// 호출 가능 — "Recorder is not open" 방지.
  Future<void> _ensureOpen() async {
    if (_isOpen) return;
    // 이 레코더는 Activity 없는 flutter_foreground_task 서비스 isolate에서 열린다.
    // flutter_sound의 recorder 채널(xyz.canardoux.flutter_sound_recorder)은
    // onAttachedToActivity에서만 등록되므로, Activity가 없으면 openRecorder가
    // MissingPluginException으로 죽는다(docs/log4.md). isBGService:true는 먼저
    // bgservice 채널의 setBGService를 호출해 Activity 없이 recorder 채널을
    // 등록(attachFlauto)시킨 뒤 세션을 연다 — flutter_sound의 백그라운드 경로.
    await _recorder.openRecorder(isBGService: true);
    _isOpen = true;
  }

  Future<void> start() async {
    if (_isRunning) return;
    await _ensureOpen(); // init을 못 거친 경로(서비스 isolate)여도 녹음 전 보장
    _buffer.clear();

    _pcmController = StreamController<Uint8List>();

    // PCM 16-bit 스트림 시작 (Uint8List 형태로 들어옴)
    await _recorder.startRecorder(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
      toStream: _pcmController!.sink,
    );

    _sub = _pcmController!.stream.listen(_onPcmData);

    _isRunning = true;
  }

  void _onPcmData(Uint8List pcm16Bytes) {
    // Int16 little-endian -> Float32 [-1, 1]
    final byteData = ByteData.sublistView(pcm16Bytes);
    final samplesCount = pcm16Bytes.length ~/ 2;

    for (int i = 0; i < samplesCount; i++) {
      final s = byteData.getInt16(i * 2, Endian.little);
      _buffer.add(s / 32768.0);
    }

    // 15600 샘플이 모일 때마다 분류 콜백 호출
    while (_buffer.length >= chunkSize) {
      final chunk = Float32List.fromList(_buffer.sublist(0, chunkSize));
      _buffer.removeRange(0, chunkSize);
      onChunk?.call(chunk);
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await _recorder.stopRecorder();
    await _sub?.cancel();
    await _pcmController?.close();
    _sub = null;
    _pcmController = null;
    _buffer.clear();
    _isRunning = false;
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.closeRecorder();
    _isOpen = false;
  }
}
