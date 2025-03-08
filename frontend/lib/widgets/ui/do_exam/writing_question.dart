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

  // 常规变量
  late WritingQuestion currQuestion;
  late WritingQuestionResult result;

  bool answerStart = false;

  // 画板控制器
  DrawingController _drawingController = DrawingController(config: DrawConfig.def(contentType: SmoothLine, color: Colors.black));

  // 截屏控制器
  ScreenshotController _screenshotController = ScreenshotController();

  @override
  void resetState() {
    currQuestion = widget.question as WritingQuestion;
    result = WritingQuestionResult(sourceQuestion: widget.question);
    answerStart = false;

    _drawingController = DrawingController(config: DrawConfig.def(contentType: SmoothLine, color: Colors.black));
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
        evalQuestion(handWriteData: handWriteData, question: currQuestion, result: result);
      } else {
        toast(context, msg: "获取手写结果失败，请联系开发者", btnText: "确认");
      }
    });
  }

  void evalQuestion({required Uint8List? handWriteData, required WritingQuestion question, required WritingQuestionResult result}) {
    result.handWriteImageData = handWriteData;

    doEvalQuestion(question: question, result: result, goToNextQuestion: widget.goToNextQuestion);
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

    List<Widget> questionBoard = [];
    if (isQuestionTextDisplayed) {
      questionBoard.add(Expanded(
          flex: 1,
          child: Center(
            child: Text(
              displayText ?? "不应该为这个",
              style: commonStyles?.titleStyle,
            ),
          )));
    }

    if (imageDisplayed) {
      questionBoard.add(Expanded(
        flex: 6,
        child: buildUrlOrAssetsImage(
          context,
          imageUrl: displayImageUrl!,
          commonStyles: commonStyles,
        ),
      ));
    } else {
      questionBoard.add(Expanded(
        flex: 6,
        child: _buildWritingArea(context, commonStyles: commonStyles, question: currQuestion),
      ));
    }

    Widget actionArea = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () {
              _drawingController.clear();
            },
            child: Text(
              "重写",
              style: commonStyles?.bodyStyle,
            )),
        const SizedBox(
          height: 48,
        ),
        ElevatedButton(
            onPressed: () {
              finishAnswer();
            },
            child: Text(
              "好了",
              style: commonStyles?.bodyStyle,
            )),
        const SizedBox(
          height: 16,
        ),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );

    Widget contentArea;
    if (questionBoard.isEmpty) {
      contentArea = Center(
        child: actionArea,
      );
    } else {
      contentArea = Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: questionBoard,
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

  Widget _buildWritingArea(BuildContext context, {CommonStyles? commonStyles, required WritingQuestion question}) {
    final mediaSize = MediaQuery.of(context).size;
    double boxWidth = mediaSize.width * 0.7;
    double boxHeight = mediaSize.height * 0.7;

    Widget drawingBoardBackground;
    if (currQuestion.imageUrl == null || currQuestion.omitImageAfterSeconds != -1) {
      drawingBoardBackground = Container(color: Colors.white, width: boxWidth, height: boxHeight,);
    } else {
      drawingBoardBackground = buildUrlOrAssetsImage(context, imageUrl: currQuestion.imageUrl!, commonStyles: commonStyles);
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
