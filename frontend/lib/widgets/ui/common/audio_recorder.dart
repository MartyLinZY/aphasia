import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:record/record.dart';

import '../../../mixin/audio_record/platform/audio_recorder_platform.dart';

class Recorder extends StatefulWidget {
  final void Function(String path)? onStop;
  final void Function(List<int> data)? onStreamModeStop;
  final AudioEncoder encoder;
  final bool streamMode;

  const Recorder(
      {super.key,
      this.onStop,
      required this.encoder,
      this.streamMode = true,
      this.onStreamModeStop})
      : assert(streamMode ? onStreamModeStop != null : onStop != null);

  @override
  State<Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<Recorder> with AudioRecorderMixin {

  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const _waveformHeight = 60.0;

  int _recordDuration = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      setState(() => _amplitude = amp);
    });

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final encoder = widget.encoder;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        final config = RecordConfig(
            encoder: encoder,
            numChannels: 1,
            sampleRate: 16000,
            bitRate: 256000);

        // Record to file
        // await recordFile(_audioRecorder, config,);

        // Record to stream
        await recordStream(_audioRecorder, config,
            onStop: widget.onStreamModeStop!);

        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      if (!widget.streamMode) {
        widget.onStop!(path);
      }

      downloadWebData(path);
    }
  }

  Future<void> _pause() => _audioRecorder.pause();

  Future<void> _resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    // return Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         _buildRecordStopControl(),
    //         const SizedBox(width: 20),
    //         _buildPauseResumeControl(),
    //         const SizedBox(width: 20),
    //         _buildText(),
    //       ],
    //     ),
    //     if (_amplitude != null) ...[
    //       const SizedBox(height: 40),
    //       Text('Current: ${_amplitude?.current ?? 0.0}'),
    //       Text('Max: ${_amplitude?.max ?? 0.0}'),
    //     ],
    //   ],
    // );
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 320),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIndicator(),
              const SizedBox(height: 24),
              _buildControlRow(),
              const SizedBox(height: 24),
              _buildTimerSection(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _recordState != RecordState.stop 
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
            Colors.transparent
          ],
          stops: const [0.5, 1.0]
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _recordState != RecordState.stop ? Icons.mic : Icons.mic_off,
          size: 40,
          color: _recordState != RecordState.stop 
            ? _getPulseColor() 
            : Colors.grey[400],
          key: ValueKey(_recordState),
        ),
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPauseResumeControl(),
        const SizedBox(width: 24),
        _buildRecordStopControl(),
      ],
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        _buildText(),
        if (_amplitude != null) ...[
          const SizedBox(height: 16),
          _buildEnhancedWaveform(),
        ],
      ],
    );
  }

  Widget _buildEnhancedWaveform() {
    return SizedBox(
      height: _waveformHeight,
      child: CustomPaint(
        painter: _WaveformPainter(
          (_amplitude?.current ?? 0.0) / (_amplitude?.max ?? 1.0),
          color: Colors.redAccent
        ),
      ),
    );
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red;
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor;
    }

    // return ClipOval(
    //   child: Material(
    //     color: color,
    //     child: InkWell(
    //       child: SizedBox(width: 56, height: 56, child: icon),
    //       onTap: () {
    //         (_recordState != RecordState.stop) ? _stop() : _start();
    //       },
    //     ),
    //   ),
    // );
    return FloatingActionButton(
      backgroundColor: color,
      onPressed: () {
        (_recordState != RecordState.stop) ? _stop() : _start();
      },
      child: icon,
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    // if (_recordState == RecordState.record) {
    //   icon = const Icon(Icons.pause, color: Colors.red, size: 30);
    //   color = Colors.red.withOpacity(0.1);
    // } else {
    //   final theme = Theme.of(context);
    //   icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
    //   color = theme.primaryColor.withOpacity(0.1);
    // }
    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.white, size: 30);
      color = Colors.orange;
    } else {
      icon = const Icon(Icons.play_arrow, color: Colors.white, size: 30);
      color = Colors.green;
    }

    // return ClipOval(
    //   child: Material(
    //     color: color,
    //     child: InkWell(
    //       child: SizedBox(width: 56, height: 56, child: icon),
    //       onTap: () {
    //         (_recordState == RecordState.pause) ? _resume() : _pause();
    //       },
    //     ),
    //   ),
    // );
    return FloatingActionButton(
      backgroundColor: color,
      onPressed: () {
        (_recordState == RecordState.pause) ? _resume() : _pause();
      },
      child: icon,
    );
  }

  Widget _buildText() {
    // if (_recordState != RecordState.stop) {
    //   return _buildTimer();
    // }

    // return const Text("Waiting to record");
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _recordState != RecordState.stop
          ? _buildTimer()
          : const Text(
              "Waiting to record",
              key: ValueKey('waiting'),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
    );
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    // return Text(
    //   '$minutes : $seconds',
    //   style: const TextStyle(color: Colors.red),
    // );
    return Text(
      '$minutes : $seconds',
      style: const TextStyle(
        color: Colors.red,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}

// 新增波形绘制类
class _WaveformPainter extends CustomPainter {
  final double amplitude;
  final Color color;

  _WaveformPainter(this.amplitude, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [color, color.withOpacity(0.5)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter
    ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = gradient
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height * amplitude;
    final centerY = size.height / 2;

    path.moveTo(0, centerY);
    for (double i = 0; i < size.width; i++) {
    final sine = sin(i * 0.3 + DateTime.now().millisecondsSinceEpoch * 0.01);
      path.lineTo(i, centerY + sine * height);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 新增动态颜色生成
Color _getPulseColor() {
  const baseColor = Colors.redAccent;
  final animationValue = (DateTime.now().millisecond % 1000) / 1000;
  return Color.lerp(baseColor, Colors.orange, sin(animationValue * pi))!;
}
