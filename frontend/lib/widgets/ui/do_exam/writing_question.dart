import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:screenshot/screenshot.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../models/result/results.dart';
import '../../../utils/common_widget_function.dart';

class WritingQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const WritingQuestionAnswerArea(
      {super.key,
      required this.question,
      required this.commonStyles,
      required this.goToNextQuestion});

  @override
  State<WritingQuestionAnswerArea> createState() =>
      _WritingQuestionAnswerAreaState();
}

class _WritingQuestionAnswerAreaState extends State<WritingQuestionAnswerArea>
    with QuestionAnswerArea
    implements ResettableState {
  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _buttonPadding =
      EdgeInsets.symmetric(horizontal: 32, vertical: 16);
  static const _actionSpacing = 24.0;
  static const _writingBorderWidth = 2.0;

  // 常规变量
  late WritingQuestion currQuestion;
  late WritingQuestionResult result;

  bool answerStart = false;

  // 画板控制器
  DrawingController _drawingController = DrawingController(
      config: DrawConfig.def(contentType: SmoothLine, color: Colors.black));

  // 截屏控制器
  ScreenshotController _screenshotController = ScreenshotController();

  @override
  void resetState() {
    currQuestion = widget.question as WritingQuestion;
    result = WritingQuestionResult(sourceQuestion: widget.question);
    answerStart = false;

    _drawingController = DrawingController(
        config: DrawConfig.def(contentType: SmoothLine, color: Colors.black));
    _screenshotController = ScreenshotController();

    initQuestionStem(currQuestion);
  }


  @override
  void finishAnswer() {
    if (imageDisplayed) {
      return;
    }

    _screenshotController.capture().then((Uint8List? handWriteData) {
      doCommonFinishStep(result);

      if (handWriteData != null) {
        evalQuestion(
            handWriteData: handWriteData,
            question: currQuestion,
            result: result);
      } else {
        toast(context, msg: "获取手写结果失败，请联系开发者", btnText: "确认");
      }
    });
  }

  void evalQuestion(
      {required Uint8List? handWriteData,
      required WritingQuestion question,
      required WritingQuestionResult result}) {
    result.handWriteImageData = handWriteData;

    doEvalQuestion(
        question: question,
        result: result,
        goToNextQuestion: widget.goToNextQuestion);
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
    disposePlayerAndCounters();
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('评分中，请稍候', style: commonStyles?.hintTextStyle),
          ],
        ),
      );
    }
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
                  widget.commonStyles?.primaryColor?.withOpacity(0.03) ??
                      Colors.white,
                  widget.commonStyles?.onPrimaryColor?.withOpacity(0.05) ??
                      Colors.white,
                ]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContentArea(widget.commonStyles),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(CommonStyles? commonStyles) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildQuestionBoard(commonStyles),
        ),
        const SizedBox(width: _actionSpacing),
        Expanded(
          flex: 1,
          child: _buildActionArea(commonStyles),
        )
      ],
    );
  }

  Widget _buildActionArea(CommonStyles? commonStyles) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          label: Text("重写",
              style: commonStyles?.bodyStyle
                  ?.copyWith(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: _buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            elevation: 4,
          ),
          onPressed: () => _drawingController.clear(),
        ),
        const SizedBox(height: _actionSpacing),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: Text("提交答案",
              style: commonStyles?.bodyStyle
                  ?.copyWith(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: commonStyles?.primaryColor ?? Colors.blueAccent,
            padding: _buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            elevation: 4,
          ),
          onPressed: finishAnswer,
        ),
        const SizedBox(height: _actionSpacing),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );
  }

  Widget _buildDrawingBoard(BuildContext context, CommonStyles? commonStyles) {
    return Screenshot(
      controller: _screenshotController,
      child: DrawingBoard(
        background: _buildBoardBackground(context, commonStyles),
        controller: _drawingController,
        showDefaultActions: false,
        showDefaultTools: false,
        boardBoundaryMargin: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildBoardBackground(
      BuildContext context, CommonStyles? commonStyles) {
    if (currQuestion.imageUrl == null) {
      return Container(color: Colors.white);
    }
    return buildUrlOrAssetsImage(context,
        imageUrl: currQuestion.imageUrl!, commonStyles: commonStyles);
  }

  Widget _buildQuestionBoard(CommonStyles? commonStyles) {
    return Column(
      children: [
        if (isQuestionTextDisplayed)
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                displayText ?? "题目文本加载中",
                style: commonStyles?.titleStyle
                    ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(
          flex: 6,
          child: imageDisplayed
              ? buildUrlOrAssetsImage(
                  context,
                  imageUrl: displayImageUrl!,
                  commonStyles: commonStyles,
                )
              : _buildWritingArea(context,
                  commonStyles: commonStyles, question: currQuestion),
        ),
      ],
    );
  }

  Widget _buildWritingArea(BuildContext context,
      {CommonStyles? commonStyles, required WritingQuestion question}) {
    final mediaSize = MediaQuery.of(context).size;
    double boxWidth = mediaSize.width * 0.7;
    double boxHeight = mediaSize.height * 0.7;

    Widget drawingBoardBackground;
    if (currQuestion.imageUrl == null ||
        currQuestion.omitImageAfterSeconds != -1) {
      drawingBoardBackground = Container(
        color: Colors.white,
        width: boxWidth,
        height: boxHeight,
      );
    } else {
      drawingBoardBackground = buildUrlOrAssetsImage(context,
          imageUrl: currQuestion.imageUrl!, commonStyles: commonStyles);
    }


    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: Screenshot(
          controller: _screenshotController,
          child: DrawingBoard(
            background: drawingBoardBackground,
            controller: _drawingController,
            showDefaultActions: false,
            showDefaultTools: false,
          ),
        ),
      ),
    );
  }
}
