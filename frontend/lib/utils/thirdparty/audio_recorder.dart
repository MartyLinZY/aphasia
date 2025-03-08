import 'dart:async';

import 'package:aphasia_recovery/mixin/audio_record/platform/audio_recorder_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

typedef Callback = void Function();

class WrappedAudioRecorder with AudioRecorderMixin{
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  RecordState _recordState = RecordState.stop;

  Amplitude? _amplitude;

  void Function(Map<String, dynamic>)? amplitudeUpdater;
  void Function(List<int>) onStop;

  WrappedAudioRecorder({this.amplitudeUpdater, required this.onStop}) {
    _initRecorder();
  }

  bool get isStopped => _recordState == RecordState.stop;
  bool get isRecording => _recordState == RecordState.record;
  bool get isPaused => _recordState == RecordState.pause;

  void _initRecorder() {
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      _amplitude = amp;
      amplitudeUpdater?.call({
        "current": _amplitude!.current,
        "max": _amplitude!.max
      });
    });
  }

  void _updateRecordState(RecordState recordState) {
    _recordState = recordState;

    switch (recordState) {
      case RecordState.pause:
        break;
      case RecordState.record:
        break;
      case RecordState.stop:
        break;
    }
  }

  Future<bool> requestPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> start({AudioEncoder? encoder}) async {
    encoder ??= AudioEncoder.pcm16bits;

    try {
      if (await _audioRecorder.hasPermission()) {

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        final config = RecordConfig(
            encoder: encoder,
            numChannels: 1,
            sampleRate: 16000,
            bitRate: 256000
        );

        // Record to file
        // await recordFile(_audioRecorder, config,);

        // Record to stream
        await recordStream(_audioRecorder, config, onStop: onStop);

      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void disposeSubscription() {
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
  }

  Future<void> stop() async {
    final path = await _audioRecorder.stop();
    amplitudeUpdater = null;
  }


  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }

  Future<void> pause() => _audioRecorder.pause();

  Future<void> resume() => _audioRecorder.resume();

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }
}