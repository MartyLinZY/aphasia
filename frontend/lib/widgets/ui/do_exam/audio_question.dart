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
    recorder = WrappedAudioRecorder(amplitudeUpdater: (map) {
      // 音量增大25时视作开始答题
      if (oldAmplitude != double.negativeInfinity &&
          map['current'] - oldAmplitude > 25) {
        _trySetAnswerTime(result, timeLimitCountDown!.timePassed);
      }

      setState(() {
        oldAmplitude = map['current'];
      });
    }, onStop: doFinishAnswer);

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
        toast(context, msg: "您似乎拒绝了授予我们麦克风权限，本题目作答需要使用麦克风对您的声音进行录制，请为我们打开麦克风权限，然后重新开始作答。", btnText: "确认");
        return;
      }

      // 启动图片展示计时器
      if (currQuestion.imageUrl != null && currQuestion.omitImageAfterSeconds != -1) {
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
    // 触发doFinishAnswer
    recorder.stop();

    player.stop();
    timeLimitCountDown!.cancel();
    imageDisplayCounter?.cancel();
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

  void _evalQuestion({String? content, required AudioQuestion question, required AudioQuestionResult result}) {
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
    recorder = WrappedAudioRecorder(amplitudeUpdater: (map) {
      setState(() {
        oldAmplitude = map['current'];
      });
    }, onStop: doFinishAnswer);

    // 初始化播放器
    player = WrappedAudioPlayer();
    player.initPlayStateSubscription();

    // 初始化答题限时计时器
    timeLimitCountDown = CountDown(widget.question.evalRule!.ansTimeLimit, onComplete: finishAnswer, onCount: (value) {
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
    if ((hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath) != null) {
      initQuestionImage();
      displayImageUrl = hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath;
    } else if (currQuestion.imageUrl != null) {
      displayImageUrl = currQuestion.imageUrl;
    }

    if (hintingRule?.hintAudioUrl == null && (hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath) == null) {
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
              child: Text('评分中，请稍候', style: commonStyles!.hintTextStyle,),
            ),
          ],
        ),
      );
    }

    List<Widget> questionInfoArea = [];
    if (isQuestionTextDisplayed) {
      questionInfoArea.add(Expanded(
          flex: 1,
          child: Center(
            child: Text(
              displayText ?? "不应该为这个",
              style: commonStyles?.titleStyle,
            ),
          )));
    }

    if (imageDisplayed) {
      questionInfoArea.add(Expanded(
        flex: 6,
        child: buildUrlOrAssetsImage(
          context,
          imageUrl: displayImageUrl!,
          commonStyles: commonStyles,
        ),
      ));
    }

    Widget actionArea = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "正在录制您的回答",
          style: commonStyles?.bodyStyle,
        ),
        const SizedBox(
          height: 16,
        ),
        ElevatedButton(
            onPressed: () {
              finishAnswer();
            },
            child: Text(
              // "完成回答$oldAmplitude",
              "结束录制",
              style: commonStyles?.bodyStyle,
            )),
        const SizedBox(
          height: 16,
        ),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );

    Widget contentArea;
    if (questionInfoArea.isEmpty) {
      contentArea = Center(
        child: actionArea,
      );
    } else {
      contentArea = Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: questionInfoArea,
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(flex: 1, child: actionArea),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: contentArea,
    );
  }

}
