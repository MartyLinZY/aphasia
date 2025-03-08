import 'dart:async';
import 'dart:math';

import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question/question.dart';
import '../models/result/results.dart';
import '../models/rules.dart';
import '../states/user_identity.dart';
import '../utils/counter.dart';
import '../utils/thirdparty/audio_player.dart';
import '../widgets/ui/login.dart';

mixin RequireLogin {
  /// 如果未登录，会导航到登陆页面，从登录页面返回后会执行callback
  bool checkLoginStatus(BuildContext context, void Function() callback, {required CommonStyles? commonStyles}) {
    var state = context.read<UserIdentity>();

    if (state.uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator
            .push(context, MaterialPageRoute(builder: (context) => LoginPage(isEntry: false, commonStyles: commonStyles,)))
            .then((_) {
          callback.call();
        });
      });
      return false;
    }

    return true;
  }
}

class CommonStyles {
  final double widgetsElevation = 16.0;
  final double listTileCommonHeight = 32;
  double? commonPaddingWidth;
  ThemeData theme;
  TextStyle? titleStyle;
  TextStyle? bodyStyle;
  TextStyle? hintTextStyle;
  Color? errorColor;
  Color? onErrorColor;
  Color? onPrimaryColor;
  Color? primaryColor;
  Color? focusListTileColor;

  bool isMedium;
  bool isLarge;
  bool isSmall;

  CommonStyles._({
    required this.theme,
    required this.titleStyle, required this.bodyStyle,
    required this.hintTextStyle, required this.errorColor,
    required this.onErrorColor, required this.primaryColor,
    required this.focusListTileColor, required this.onPrimaryColor,
    required this.isLarge, required this.isMedium,
    required this.isSmall, required this.commonPaddingWidth
  });
}

mixin UseCommonStyles {
  CommonStyles? commonStyles;

  CommonStyles initStyles(BuildContext context) {
    var theme = Theme.of(context);
    var media = MediaQuery.of(context);

    TextStyle? titleStyle = theme.textTheme.titleMedium;
    TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    TextStyle? hintTextStyle = theme.textTheme.displaySmall;

    double commonPaddingWidth = 18;

    // 1 small, 2 medium, 3 large
    int sizeFlag = 1;

    if (media.size.height > 800) {
      sizeFlag = 2;
      titleStyle = theme.textTheme.titleLarge;
      bodyStyle = theme.textTheme.bodyLarge;
      hintTextStyle = theme.textTheme.displayMedium;

      commonPaddingWidth = 27;

      if (media.size.height > 1200) {
        sizeFlag = 3;

        commonPaddingWidth = 36;
      }
    }

    var errorColor = theme.colorScheme.error;
    var onErrorColor = theme.colorScheme.onError;
    var primaryColor = theme.colorScheme.primary;
    var focusListTileColor = theme.focusColor.withBlue(200);

    commonStyles = CommonStyles._(
      theme: theme,
      titleStyle: titleStyle,
      bodyStyle: bodyStyle,
      hintTextStyle: hintTextStyle,
      errorColor: errorColor,
      onErrorColor: onErrorColor,
      primaryColor: primaryColor,
      focusListTileColor: focusListTileColor,
      onPrimaryColor: theme.colorScheme.onPrimary,
      isSmall: sizeFlag == 1,
      isMedium: sizeFlag == 2,
      isLarge: sizeFlag == 3,
      commonPaddingWidth: commonPaddingWidth,
    );

    return commonStyles!;
  }
}

mixin AudioPlayerSetting {
  /// 需要在[State.initState]中将该变量初始化为[State.setState]函数
  late void Function(void Function() fn) setStateProxy;

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

  Future<void> play() async {
    await player.resume();
    // setStateProxy(() => player.state = PlayerState.playing);
  }

  Future<void> pause() async {
    await player.pause();
    // setStateProxy(() => player.state = PlayerState.paused);
  }

  Future<void> stop() async {
    await player.stop();
    setStateProxy(() {
      // player.state = PlayerState.stopped;
      playPosition = Duration.zero;
    });
  }

  void setupPlayer(String url) {
    player.setSource(UrlSource(url));
    player.getDuration().then(
          (value) => setStateProxy(() {
        audioDuration = value;
      }),
    );
    player.getCurrentPosition().then(
          (value) => setStateProxy(() {
        playPosition = value;
      }),
    );
  }

  /// 请在[State.initState]中调用
  void initPlayStateSubscription() {
    _durationSubscription = player.onDurationChanged.listen((newDuration) {
      setStateProxy(() => audioDuration = newDuration);
    });

    _positionSubscription = player.onPositionChanged.listen(
          (p) => setStateProxy(() => playPosition = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setStateProxy(() {
        playPosition = Duration.zero;
      });
    });

    // _playerStateChangeSubscription =
    //     player.onPlayerStateChanged.listen((state) {
    //       setStateProxy(() {
    //       });
    //     });
  }

  /// 请在[State.dispose]中调用
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

mixin class TextFieldCommonValidators {
  String? Function(String?) notEmptyValidator(String fieldName) {
    return (String? value) {
      if ((value ?? "") == "") {
        return "$fieldName不可为空";
      }
      return null;
    };
  }

  String? needChineseValidator(String? value) {
    if (!isChineseString(value!)) {
      return "请输入中文";
    }
    return null;
  }

  String? needIntValidator(String? value) {
    if (int.tryParse(value!) == null) {
      return "请输入整数";
    }
    return null;
  }

  String? Function(String? value) needGreaterThanOrEqualIntValidator(int min) {
    return (String? value) {
      String? errMsg = needIntValidator(value!);
      if (errMsg == null && int.parse(value) < min) {
        return "请输入大于等$min的整数";
      }
      return errMsg;
    };
  }

  String? needDoubleValidator(String? value) {
    if (double.tryParse(value!) == null) {
      return "请输入数字";
    }
    return null;
  }

  String? Function(String? value) needGreaterThanOrEqualDoubleValidator(double min) {
    return (String? value) {
      String? errMsg = needDoubleValidator(value!);
      if (errMsg == null && double.parse(value) < min) {
        return "请输入大于等于$min的数";
      }
      return errMsg;
    };
  }

  String? Function(String? value) needSmallerThanOrEqualDoubleValidator(double max) {
    return (String? value) {
      String? errMsg = needDoubleValidator(value!);
      if (errMsg == null && double.parse(value) > max) {
        return "请输入小于等于$max的数";
      }
      return errMsg;
    };
  }

}

abstract class ResettableState {
  void resetState();
}

class FieldSetting {
  final GlobalKey<FormFieldState> key;
  final TextEditingController ctrl;
  final String? Function(String?) validator;
  final void Function() reset;
  final void Function() applyToModel;

  FieldSetting({required this.key, required this.ctrl, required this.validator, required this.reset, required this.applyToModel});
}

mixin StateWithTextFields {
  final Map<String, FieldSetting> fieldsSetting = {};

  void initFieldSettings();

  bool applyFieldsChangesToModel() {
    if (validateAllFields()) {
      fieldsSetting.forEach((key, value) => value.applyToModel());
      return true;
    }
    return false;
  }

  void resetAllFields() {
    fieldsSetting.forEach((key, value) => value.reset());
  }

  bool validateAllFields() {
    return fieldsSetting.entries
        .map((e) => e.value.key.currentState?.validate() ?? true)
        .fold(true, (prev, valid) => prev && valid);
  }
}

mixin QuestionImage {
  CountDown? imageDisplayCounter;
  bool imageDisplayed = false;

  void initQuestionImage() {
    imageDisplayed = true;
  }

  void startQuestionImageFadeCountDown(Question question, {void Function()? onImageFaded}) {
    final omitTime = question.omitImageAfterSeconds;
    // 将图片显示时间限制在1秒到图片最大显示时间之间
    imageDisplayCounter = CountDown(
      min(max(omitTime, 1), Question.maxOmitTime),
      onComplete: () {
        imageDisplayed = false;
        onImageFaded?.call();
      }
    );
    imageDisplayCounter!.start();
  }
}

mixin QuestionText {
  bool isQuestionTextDisplayed = false;

  void initQuestionText() {
    isQuestionTextDisplayed = true;
  }
}

mixin QuestionAnswerArea {
  // 播放器
  WrappedAudioPlayer? player;

  // 答题限时counter
  CountDown? timeLimitCountDown;

  CountDown? imageDisplayCounter;
  bool imageDisplayed = false;

  // 图片计时器相关
  void setImageDisplayed() {
  }

  void displayImageWithFadeCountDown(Question question, {void Function()? onImageFaded}) {
    imageDisplayed = true;
    final omitTime = question.omitImageAfterSeconds;
    // 将图片显示时间限制在1秒到图片最大显示时间之间
    imageDisplayCounter = CountDown(
        min(max(omitTime, 1), Question.maxOmitTime),
        onComplete: () {
          imageDisplayed = false;
          onImageFaded?.call();
        }
    );
    imageDisplayCounter!.start();
  }

  // 题干文本相关
  bool isQuestionTextDisplayed = false;

  void setQuestionTextDisplayed() {
    isQuestionTextDisplayed = true;
  }

  // 常规变量
  HintRule? hintingRule;
  bool get hinting => hintingRule != null;

  bool evaluating = false;

  String? displayImageUrl;
  String? displayText;


  void initQuestionStem(Question currQuestion) {
    hintingRule = null;
    evaluating = false;

    // 初始化播放器
    player = WrappedAudioPlayer();
    player!.initPlayStateSubscription();

    // 初始化答题限时计时器
    timeLimitCountDown = CountDown(currQuestion.evalRule!.ansTimeLimit,
        onComplete: finishAnswer, onCount: (value) {
          setState(() {});
        });

    // 初始化题干（设置展示图片，设置图片展示计时器，设置音频播放器）
    // debugPrint(currQuestion.toJson().toString());

    // 初始化题干文本
    if ((currQuestion.questionText ?? "") != "") {
      setQuestionTextDisplayed();
      displayText = currQuestion.questionText;
    }

    // 初始化音频
    if (currQuestion.audioUrl != null) {
      player!.setup(currQuestion.audioUrl!, onComplete: () {
        setState(() {
          tryStartTimeLimitCounter(currQuestion);
        });
      });

      player!.play();
    }

    // 初始化展示图片并启动展示计时器
    if (currQuestion.imageUrl != null){
      displayImageUrl = currQuestion.imageUrl;

      if (currQuestion.omitImageAfterSeconds == -1) {
        currQuestion.omitImageAfterSeconds == Question.maxOmitTime;
      }

      displayImageWithFadeCountDown(currQuestion, onImageFaded: () {
        setState(() {
          // 图片和录音展示完毕后启动题目作答倒计时
          tryStartTimeLimitCounter(currQuestion);
        });
      });
    } else if (currQuestion.audioUrl == null) {
      tryStartTimeLimitCounter(currQuestion);
    } else {
      // 不需要做任何操作，把启动答题时间计时器的操作交给题干音频
    }
  }

  void trySetAnswerTime(QuestionResult result, int timePassed) {
    result.answerTime ??= timePassed;
  }

  void tryStartTimeLimitCounter(Question question) {
    // debugPrint("tryStartTimeLimitCounter*************************************************************************************");
    // debugPrint("player.isPlaying: ${player?.isPlaying}");
    // debugPrint("imageDisplayed: ${player?.isPlaying}");
    if (!player!.isPlaying) {
      if (imageDisplayed && question.omitImageAfterSeconds == -1 ||
          !imageDisplayed) {
        timeLimitCountDown!.start();
      }
    }
  }

  void finishAnswer();

  void doCommonFinishStep(QuestionResult result) {
    player!.stop();
    setState(() {
      evaluating = true;
    });

    trySetAnswerTime(result, timeLimitCountDown!.timePassed);
    timeLimitCountDown!.cancel();
    imageDisplayCounter?.cancel();
  }

  void setState(void Function() fn);

  Future<void> doEvalQuestion({required Question question, required QuestionResult result, required void Function(QuestionResult) goToNextQuestion}) async {
    await question.evalRule!.evaluate(result);

    // debugPrint(result.toJson().toString());
    if (!hinting) {
      triggerHint(question, result, goToNextQuestion);
    } else {
      // hintingRule?.adjustScore(result);
      // debugPrint("提示后：${result.extraResults}");
      debugPrint("最终得分：${result.finalScore}");
      goToNextQuestion(result);
    }
  }

  void triggerHint(Question currQuestion, QuestionResult result, void Function(QuestionResult) goToNextQuestion) {
    hintingRule = currQuestion.evalRule!.getMatchHintRule(result.finalScore!);
    if (hintingRule != null) {
      setState(() {
        setHintStates(currQuestion);
        result.isHinted = true;
      });
    } else {
      debugPrint("最终得分：${result.finalScore}");
      goToNextQuestion(result);
    }
  }

  void setHintStates(Question currQuestion) {
    evaluating = false;

    // 重设播放器
    player = WrappedAudioPlayer();
    player!.initPlayStateSubscription();

    // 重设答题限时计时器
    timeLimitCountDown = CountDown(currQuestion.evalRule!.ansTimeLimit, onComplete: finishAnswer, onCount: (value) {
      // 刷新倒计时的文本
      setState(() {});
    });

    // 初始化提示时的题干（设置展示图片，设置图片展示计时器，设置音频播放器）
    if ((hintingRule?.hintText ?? "") != "") {
      setQuestionTextDisplayed();
      displayText = "提示：${hintingRule?.hintText}";
    }

    if (hintingRule?.hintAudioUrl != null) {
      player!.setup(hintingRule!.hintAudioUrl!, onComplete: () {
        tryStartTimeLimitCounter(currQuestion);
      });

      player!.play();
    }

    if ((hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath) != null) {
      displayImageUrl = hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath;

      displayImageWithFadeCountDown(currQuestion, onImageFaded: () {
        setState(() {
          // 图片和录音展示完毕后启动题目作答倒计时
          tryStartTimeLimitCounter(currQuestion);
        });
      });
    } else if (currQuestion.imageUrl != null) {
      // 没有提示图片时用题干图片做提示
      displayImageUrl = currQuestion.imageUrl;

      displayImageWithFadeCountDown(currQuestion, onImageFaded: () {
        setState(() {
          // 图片和录音展示完毕后启动题目作答倒计时
          tryStartTimeLimitCounter(currQuestion);
        });
      });
    }

    // 如果没有音频也没有图片，直接开始答题倒计时
    if (hintingRule?.hintAudioUrl == null && (hintingRule?.hintImageUrl ?? hintingRule?.hintImageAssetPath ?? currQuestion.imageUrl) == null) {
      timeLimitCountDown?.start();
    } else {
      // 否则等到音频结束或图片消失时时开始倒计时
    }

    // 重新设置作答结果变量
    resetAnswerStateAfterHint(currQuestion.evalRule!);
  }

  /// 如果需要在hint之后重新设置答题状态，实现该方法
  void resetAnswerStateAfterHint(QuestionEvalRule rule) {}

  void disposePlayerAndCounters() {
    player?.disposePlayStateSubscription();
    player?.dispose();
    timeLimitCountDown?.cancel();
    imageDisplayCounter?.cancel();

  }
}

