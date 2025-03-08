import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../mixin/widgets_mixin.dart';

class WrappedAudioPlayer {
  // 播放器相关变量
  AudioPlayer player = AudioPlayer();

  Duration? audioDuration;
  Duration? playPosition;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  // StreamSubscription? _playerStateChangeSubscription;

  bool get isPlaying => player.state == PlayerState.playing;
  bool get isPaused => player.state == PlayerState.paused;
  bool get isPlayerDisposed => player.state == PlayerState.disposed;

  String get durationText => audioDuration?.toString().split('.').first ?? '';

  String get positionText => playPosition?.toString().split('.').first ?? '';

  // void Function()? onStop;
  void Function()? onComplete;

  Future<void> play() async {
    // player.setVolume(0);
    // final volume = player.volume;
    // Timer(const Duration(milliseconds: 500), () {
    //   player.setVolume(volume);
    // });
    await player.resume();
    // setStateProxy(() => player.state = PlayerState.playing);
  }

  Future<void> pause() async {
    await player.pause();
    // setStateProxy(() => player.state = PlayerState.paused);
  }

  Future<void> stop() async {
    await player.stop();
      // player.state = PlayerState.stopped;
    playPosition = Duration.zero;
    onComplete = null;
  }

  Future<void> dispose() async {
    await player.dispose();
    disposePlayStateSubscription();
  }

  void setup(String url, {void Function()? onComplete}) {
    this.onComplete = onComplete;
    player.setSource(UrlSource(url));
    player.getDuration().then((value) => audioDuration = value);
    player.getCurrentPosition().then((value) => playPosition = value);
  }

  /// 在[State.initState]中调用
  void initPlayStateSubscription ({
    void Function(Duration)? onDurationChange,
    void Function(Duration)? onPlayPositionChange,
  }) {
    _durationSubscription = player.onDurationChanged.listen((newDuration) {
      audioDuration = newDuration;
      onDurationChange?.call(newDuration);
    });

    _positionSubscription = player.onPositionChanged.listen((p) {
      playPosition = p;
      onPlayPositionChange?.call(p);
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      playPosition = Duration.zero;
      onComplete?.call();
    });

    // _playerStateChangeSubscription =
    //     player.onPlayerStateChanged.listen((state) {
    //       setStateProxy(() {
    //       });
    //     });
  }

  /// 在[State.dispose]中调用
  void disposePlayStateSubscription() {
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _positionSubscription?.cancel();
    // _playerStateChangeSubscription?.cancel();
  }

  Widget buildPlayer({CommonStyles? commonStyles}) {
    Widget playBtn;

    if (isPlaying) {
      playBtn = IconButton(
        key: const Key('play_btn'),
        onPressed: pause,
        icon: const Icon(Icons.pause),
        iconSize: 24,
        color: commonStyles?.primaryColor,
      );
    } else {
      playBtn = IconButton(
        key: const Key('pause_btn'),
        onPressed: isPlayerDisposed ? null : play,
        icon: const Icon(Icons.play_arrow),
        iconSize: 24,
        color: commonStyles?.primaryColor,
      );
    }

    return Column(
      children: [
        Row(
          children: [
            playBtn,
            IconButton(
              key: const Key('stop_btn'),
              onPressed: isPlaying || isPaused ? stop : null,
              icon: const Icon(Icons.stop),
              iconSize: 24,
              color: commonStyles?.primaryColor,
            )
          ],
        ),
        Slider(
          onChanged: (value) {
            final duration = audioDuration;
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (playPosition != null &&
              audioDuration != null &&
              playPosition!.inMilliseconds > 0 &&
              playPosition!.inMilliseconds < audioDuration!.inMilliseconds)
              ? playPosition!.inMilliseconds / audioDuration!.inMilliseconds
              : 0.0,
        ),
        Text(
          playPosition != null
              ? '$positionText / $durationText'
              : audioDuration != null
              ? durationText
              : '',
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }
}