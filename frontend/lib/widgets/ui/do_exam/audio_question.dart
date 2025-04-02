import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aphasia_recovery/enum/system.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/utils/counter.dart';
import 'package:aphasia_recovery/utils/thirdparty/audio_recorder.dart';
import 'package:aphasia_recovery/utils/thirdparty/thirdparty_api.dart';
import 'package:flutter/material.dart';

import '../../../utils/thirdparty/audio_player.dart';

class AudioQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const AudioQuestionAnswerArea(
      {super.key,
      required this.question,
      required this.commonStyles,
      required this.goToNextQuestion});

  @override
  State<AudioQuestionAnswerArea> createState() =>
      _AudioQuestionAnswerAreaState();
}

class _AudioQuestionAnswerAreaState extends State<AudioQuestionAnswerArea>
    with QuestionImage, QuestionText
    implements ResettableState {
  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _buttonPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const _amplitudeAnimationDuration = Duration(milliseconds: 100);
  bool _noRecordingDevice = false; // 新增设备状态标识

  // 录音相关变量
  late WrappedAudioRecorder recorder;
  double oldAmplitude = double.negativeInfinity;

  // 播放器
  late WrappedAudioPlayer player;

  // 答题限时counter
  CountDown? timeLimitCountDown;

  // 常规变量
  late AudioQuestion currQuestion;
  late AudioQuestionResult result;

  HintRule? hintingRule;
  bool get hinting => hintingRule != null;

  bool evaluating = false;

  String? displayImageUrl;
  String? displayText;

  @override
  void resetState() {
    currQuestion = widget.question as AudioQuestion;
    result = AudioQuestionResult(sourceQuestion: widget.question);
    hintingRule = null;
    evaluating = false;

    // 初始化录音器
    recorder = WrappedAudioRecorder(
        amplitudeUpdater: (map) {
          // 音量增大25时视作开始答题
          if (oldAmplitude != double.negativeInfinity &&
              map['current'] - oldAmplitude > 25) {
            _trySetAnswerTime(result, timeLimitCountDown!.timePassed);
          }

          setState(() {
            oldAmplitude = map['current'];
          });
        },
        onStop: doFinishAnswer);

    // 初始化播放器
    player = WrappedAudioPlayer();
    player.initPlayStateSubscription();

    // 初始化答题限时计时器
    timeLimitCountDown = CountDown(widget.question.evalRule!.ansTimeLimit,
        onComplete: finishAnswer, onCount: (value) {
      setState(() {});
    });

    // 初始化题干（设置展示图片，设置图片展示计时器，设置音频播放器）
    initQuestionStem();

    // 先申请权限然后再启动播放器和计时器
    recorder.requestPermission().then((value) {
      if (!value) {
        setState(() {
          _noRecordingDevice = true; // 更新设备状态
        });
        toast(context,
            msg: "您似乎拒绝了授予我们麦克风权限，本题目作答需要使用麦克风对您的声音进行录制，请为我们打开麦克风权限，然后重新开始作答。",
            btnText: "确认");
        return;
      }

      // 启动图片展示计时器
      if (currQuestion.imageUrl != null &&
          currQuestion.omitImageAfterSeconds != -1) {
        startQuestionImageFadeCountDown(currQuestion);
      }

      // 没有题干音频的时候，直接开始答题倒计时
      if (currQuestion.audioUrl == null) {
        _startTimeLimitCounter();
      } else {
        // 不需要操作，等到音频放完会启动答题倒计时
      }

      if (currQuestion.audioUrl != null) {
        // 启动播放器
        player.play();
      }

      // 启动录音
      recorder.start();

      // timeLimitCountDown!.start();
    });
  }

  void _trySetAnswerTime(QuestionResult result, int timePassed) {
    result.answerTime ??= timePassed;
  }

  void initQuestionStem() {
    final currQuestion = widget.question;
    // debugPrint(currQuestion.toJson().toString());

    // 初始化题干文本
    if ((currQuestion.questionText ?? "") != "") {
      initQuestionText();
      displayText = currQuestion.questionText;
    }

    // 初始化音频
    if (currQuestion.audioUrl != null) {
      player.setup(currQuestion.audioUrl!, onComplete: () {
        setState(() {
          _startTimeLimitCounter();
        });
      });
    }

    // 初始化图片展示倒计时
    if (currQuestion.imageUrl != null) {
      initQuestionImage();
      displayImageUrl = currQuestion.imageUrl;
    }
  }

  void _startTimeLimitCounter() {
    timeLimitCountDown!.start();
  }

  void finishAnswer() {
    // 修改结束逻辑
    recorder.stop();
    player.stop();
    timeLimitCountDown?.cancel();
    imageDisplayCounter?.cancel();

    if (_noRecordingDevice) {
      // 无设备时立即提交结果
      final result = AudioQuestionResult(sourceQuestion: widget.question);
      widget.goToNextQuestion(result);
    }

    // if (_noRecordingDevice) return;

    // // 触发doFinishAnswer
    // recorder.stop();

    // player.stop();
    // timeLimitCountDown!.cancel();
    // imageDisplayCounter?.cancel();
  }

  void doFinishAnswer(List<int> rawPcm16Data) {
    setState(() {
      evaluating = true;
    });

    if (currQuestion.evalRule is EvalAudioQuestionByFluency) {
      result.rawPcm16Data = rawPcm16Data;
      // 流畅度评分不需要先获取内容
      _evalQuestion(question: currQuestion, result: result);
    } else {
      // 其他规则先获取内容再触发评分
      recognizeAudioContent(rawPcm16Data).then((content) {
        _trySetAnswerTime(result, timeLimitCountDown!.timePassed);

        _evalQuestion(content: content, result: result, question: currQuestion);
      });
    }
  }

  void _evalQuestion(
      {String? content,
      required AudioQuestion question,
      required AudioQuestionResult result}) {
    if (content != null) {
      result.audioContent = content;
    }

    question.evalRule!.evaluate(result).then((value) {
      debugPrint(result.toJson().toString());
      if (!hinting) {
        _triggerHint(currQuestion, result);
      } else {
        widget.goToNextQuestion(result);

        debugPrint("最终得分：${result.finalScore}");
      }
    });
  }

  void _triggerHint(AudioQuestion currQuestion, AudioQuestionResult result) {
    hintingRule = currQuestion.evalRule!.getMatchHintRule(result.finalScore!);
    if (hintingRule != null) {
      setState(() {
        _setHintStates();
        result.isHinted = true;
      });
    } else {
      // hintingRule?.adjustScore(result);
      widget.goToNextQuestion(result);
    }
  }

  _setHintStates() {
    evaluating = false;

    // 初始化录音器
    recorder = WrappedAudioRecorder(
        amplitudeUpdater: (map) {
          setState(() {
            oldAmplitude = map['current'];
          });
        },
        onStop: doFinishAnswer);

    // 初始化播放器
    player = WrappedAudioPlayer();
    player.initPlayStateSubscription();

    // 初始化答题限时计时器
    timeLimitCountDown = CountDown(widget.question.evalRule!.ansTimeLimit,
        onComplete: finishAnswer, onCount: (value) {
      setState(() {});
    });

    // 初始化提示时的题干（设置展示图片，设置图片展示计时器，设置音频播放器）
    if ((hintingRule?.hintText ?? "") != "") {
      initQuestionText();
      displayText = hintingRule?.hintText;
    }
    if (hintingRule?.hintAudioUrl != null) {
      player.setup(hintingRule!.hintAudioUrl!, onComplete: () {
        timeLimitCountDown?.start();
      });

      // 启动播放器
      player.play();
    }
    if ((hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath) !=
        null) {
      initQuestionImage();
      displayImageUrl =
          hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath;
    } else if (currQuestion.imageUrl != null) {
      displayImageUrl = currQuestion.imageUrl;
    }

    if (hintingRule?.hintAudioUrl == null &&
        (hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath) ==
            null) {
      timeLimitCountDown?.start();
    }

    // 启动录音
    recorder.start();
  }

  @override
  void initState() {
    super.initState();

    resetState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    player.disposePlayStateSubscription();
    player.dispose();
    recorder.disposeSubscription();
    timeLimitCountDown?.cancel();
    imageDisplayCounter?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currQuestion != widget.question) {
      // 题目切换
      resetState();
    }

    if (_noRecordingDevice) {
      return _buildDeviceErrorUI(context); // 无设备时的专用界面
    }

    final commonStyles = widget.commonStyles;

    if (evaluating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '评分中，请稍候',
                style: commonStyles!.hintTextStyle,
              ),
            ),
          ],
        ),
      );
    }

    // List<Widget> questionInfoArea = [];
    // if (isQuestionTextDisplayed) {
    //   questionInfoArea.add(Expanded(
    //       flex: 1,
    //       child: Center(
    //         child: Text(
    //           displayText ?? "不应该为这个",
    //           style: commonStyles?.titleStyle,
    //         ),
    //       )));
    // }

    // if (imageDisplayed) {
    //   questionInfoArea.add(Expanded(
    //     flex: 6,
    //     child: buildUrlOrAssetsImage(
    //       context,
    //       imageUrl: displayImageUrl!,
    //       commonStyles: commonStyles,
    //     ),
    //   ));
    // }

    // Widget actionArea = Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Text(
    //       "正在录制您的回答",
    //       style: commonStyles?.bodyStyle,
    //     ),
    //     const SizedBox(
    //       height: 16,
    //     ),
    //     ElevatedButton(
    //         onPressed: () {
    //           finishAnswer();
    //         },
    //         child: Text(
    //           // "完成回答$oldAmplitude",
    //           "结束录制",
    //           style: commonStyles?.bodyStyle,
    //         )),
    //     const SizedBox(
    //       height: 16,
    //     ),
    //     timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
    //   ],
    // );

    // Widget contentArea;
    // if (questionInfoArea.isEmpty) {
    //   contentArea = Center(
    //     child: actionArea,
    //   );
    // } else {
    //   contentArea = Row(
    //     children: [
    //       Expanded(
    //         flex: 4,
    //         child: Column(
    //           children: questionInfoArea,
    //         ),
    //       ),
    //       const SizedBox(
    //         width: 8.0,
    //       ),
    //       Expanded(flex: 1, child: actionArea),
    //     ],
    //   );
    // }

    // return Padding(
    //   padding: const EdgeInsets.all(16.0),
    //   child: contentArea,
    // );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                commonStyles?.primaryColor?.withOpacity(0.03) ?? Colors.white,
                commonStyles?.onPrimaryColor?.withOpacity(0.05) ?? Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildEnhancedContent(commonStyles),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedContent(CommonStyles? commonStyles) {
    return Column(
      children: [
        Expanded(
          child: _buildAnimatedQuestionArea(commonStyles),
        ),
        _buildVisualFeedback(commonStyles),
        const SizedBox(height: 20),
        _buildActionPanel(commonStyles),
      ],
    );
  }

  Widget _buildAnimatedQuestionArea(CommonStyles? commonStyles) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: (imageDisplayed || isQuestionTextDisplayed)
          ? _buildQuestionInfoArea(commonStyles)
          : _buildPlaceholder(commonStyles),
    );
  }

  Widget _buildPlaceholder(CommonStyles? commonStyles) {
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.mic_none,
        size: 120,
        color: commonStyles?.primaryColor?.withOpacity(0.2),
      ),
    );
  }

  Widget _buildActionPanel(CommonStyles? commonStyles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAmplitudeIndicator(commonStyles),
          const SizedBox(height: 20),
          _buildRecordingStatus(commonStyles),
          const SizedBox(height: 20),
          _buildControlButtons(commonStyles),
        ],
      ),
    );
  }

// 新增振幅指示器组件
  Widget _buildAmplitudeIndicator(CommonStyles? commonStyles) {
    return AnimatedContainer(
      duration: _amplitudeAnimationDuration,
      width: (oldAmplitude != double.negativeInfinity)
          ? (100 + (oldAmplitude.abs() / 5)).clamp(120, 300)
          : 120,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: [
            commonStyles?.primaryColor?.withOpacity(0.6) ?? Colors.blue,
            commonStyles?.errorColor ?? Colors.red,
          ],
        ),
      ),
    );
  }

  // 新增录音状态组件
  Widget _buildRecordingStatus(CommonStyles? commonStyles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, 
            size: 20,
            color: commonStyles?.primaryColor),
        const SizedBox(width: 8),
        Text(
          timeLimitCountDown?.timeLeft != null 
              ? "剩余 ${timeLimitCountDown!.timeLeft ~/ 60}:${(timeLimitCountDown!.timeLeft % 60).toString().padLeft(2, '0')}"
              : "正在录音...",
          style: commonStyles?.bodyStyle?.copyWith(
            fontSize: 14,
            color: commonStyles?.primaryColor
          ),
        ),
      ],
    );
  }

    // 新增视觉反馈组件
  Widget _buildVisualFeedback(CommonStyles? commonStyles) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volume_up, 
              color: commonStyles?.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text("音量检测中...",
              style: commonStyles?.bodyStyle?.copyWith(
                color: commonStyles?.primaryColor,
                fontSize: 14
              )),
        ],
      ),
    );
  }

  // 重构题干信息区域
  Widget _buildQuestionInfoArea(CommonStyles? commonStyles) {
    return Column(
      children: [
        if (isQuestionTextDisplayed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              displayText ?? "",
              style: commonStyles?.titleStyle?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        if (imageDisplayed)
          Expanded(
            child: buildUrlOrAssetsImage(
              context,
              imageUrl: displayImageUrl!,
              commonStyles: commonStyles,
            ),
          ),
      ],
    );
  }

  // 新增控制按钮组
  Widget _buildControlButtons(CommonStyles? commonStyles) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.stop, color: Colors.white),
        label: Text("结束录制", 
            style: commonStyles?.bodyStyle?.copyWith(
              color: Colors.white,
              fontSize: 16
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: commonStyles?.errorColor ?? Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: finishAnswer,
      ),
    );
  }

  // 新增错误提示组件
  Widget _buildDeviceErrorUI(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(minHeight: 200), // 添加最小高度约束
        child: Column(
          mainAxisSize: MainAxisSize.min, // 设置为最小高度
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Padding(
              // Add padding container
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "未检测到录音设备\n无法进行语音题作答",
                style: widget.commonStyles?.titleStyle
                    ?.copyWith(fontSize: 24, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.skip_next),
              label: const Text("跳过本题"),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blueAccent, elevation: 2),
              onPressed: () {
                widget.goToNextQuestion(AudioQuestionResult(
                  sourceQuestion: widget.question,
                ));
                finishAnswer();
              },
            )
          ],
        ),
      ),
    );
  }
}
