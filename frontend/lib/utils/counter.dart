import 'dart:async';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:flutter/material.dart';

class CountDown {
  Timer? _timer;
  int _currCount;
  final int maxCount;
  void Function(int)? onCount;
  void Function()? onComplete;
  bool _isComplete;

  int get timePassed => maxCount - _currCount;

  int get timeLeft => _currCount;

  bool get isComplete => _isComplete;

  CountDown(this.maxCount, {this.onCount, this.onComplete})
    : _currCount = maxCount,
      _isComplete = false;

  void start() {
    _timer?.cancel();
    _currCount = maxCount;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currCount--;
      if (onCount != null) onCount!(_currCount);
      if (_currCount == 0) {
        complete();
      }
    });
  }

  void complete() {
    final onStop = onComplete;

    _timer?.cancel();
    onComplete = null;
    onCount = null;
    _isComplete = true;

    onStop?.call();
  }

  void cancel() {
    _timer?.cancel();
  }

  Widget buildCountWidget({required CommonStyles? commonStyles}) {
    return Text("倒计时: $_currCount", style: commonStyles?.bodyStyle?.copyWith(  // 使用bodyStyle为基础样式
        fontSize: 28,
        color: Colors.red
      ),);
  }
}

class Counter {
  Timer? _timer;
  int _currCount;
  final int maxCount;
  void Function(int)? onCount;
  void Function(int)? onComplete;

  int get timePassed => _currCount;

  Counter(this.maxCount, {this.onCount, this.onComplete})
      : _currCount = 0;

  void start() {
    _timer?.cancel();
    _currCount = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currCount++;
      if (onCount != null) onCount!(_currCount);
      if (_currCount == maxCount) {
        _complete();
      }
    });
  }

  void _complete() {
    final onComplete = this.onComplete;
    _timer?.cancel();

    this.onComplete = null;
    onCount = null;

    onComplete?.call(_currCount);
  }

  void cancel() {
    _timer?.cancel();
  }

  Widget buildCountWidget({required CommonStyles? commonStyles}) {
    return Text("计时: $_currCount", style: commonStyles?.bodyStyle?.copyWith(  // 使用bodyStyle为基础样式
        fontSize: 28,
        color: commonStyles.onErrorColor
      ),);
  }
}
