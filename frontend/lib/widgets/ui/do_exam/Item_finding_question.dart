import 'dart:async';
import 'dart:ui' as ui;

import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../models/result/results.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/assets.dart';

class ItemFindingQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const ItemFindingQuestionAnswerArea(
      {super.key,
        required this.question,
        required this.commonStyles,
        required this.goToNextQuestion});

  @override
  State<ItemFindingQuestionAnswerArea> createState() =>
      _ItemFindingQuestionAnswerAreaState();
}

class _ItemFindingQuestionAnswerAreaState extends State<ItemFindingQuestionAnswerArea>
    with QuestionAnswerArea
    implements ResettableState {

  // 常规变量
  late ItemFindingQuestion currQuestion;
  late ItemFindingQuestionResult result;

  bool answerStart = false;
  List<double>? clickPosition;

  @override
  void resetState() {
    currQuestion = widget.question as ItemFindingQuestion;
    EvalItemFoundQuestion rule = currQuestion.evalRule as EvalItemFoundQuestion;
    result = ItemFindingQuestionResult(sourceQuestion: widget.question);
    answerStart = false;

    initQuestionStem(currQuestion);

    // 关闭答题倒计时，测试用
    // timeLimitCountDown?.cancel();
  }

  @override
  void initQuestionStem(Question currQuestion) {
    super.initQuestionStem(currQuestion);
    // 本题型的题干图片展示方式不同，所以不需要通用的题干图片相关功能
    imageDisplayed = false;
    imageDisplayCounter!.cancel();

    // 由于图片展示方式不同，所以当没有音频时直接启动答题计时器
    if (currQuestion.audioUrl == null) {
      timeLimitCountDown!.start();
    }
  }

  @override
  void finishAnswer() {
    if (!timeLimitCountDown!.isComplete) {
      if (clickPosition == null) {
        return;
      }
    }

    doCommonFinishStep(result);

    evalQuestion(clickPosition: clickPosition, result: result, question: currQuestion);
  }

  void evalQuestion({required List<double>? clickPosition, required ItemFindingQuestion question, required ItemFindingQuestionResult result}) {
    result.clickCoordinate = clickPosition;

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

    questionBoard.add(Expanded(
      flex: 6,
      child: _buildItemFindingArea(context, commonStyles: commonStyles, question: currQuestion),
    ));

    Widget actionArea = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  Widget _buildItemFindingArea(BuildContext context, {CommonStyles? commonStyles, required ItemFindingQuestion question}) {
    final imageCompleter = Completer<ui.Image>();
    Image questionImage;
    if (isImageUrlAssets(currQuestion.imageUrl)) {
      questionImage = Image(image: AssetImage(currQuestion.imageUrl!), fit: BoxFit.contain,);
    } else {
      questionImage = Image(
        image: NetworkImage(currQuestion.imageUrl!),
        fit: BoxFit.contain,
      );
    }

    questionImage.image.resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, _) {
      imageCompleter.complete(imageInfo.image);
    }));


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<ui.Image>(
              future: imageCompleter.future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  toast(context, msg: "图片加载失败，请重试。", btnText: "确认");
                  return Center(
                    child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                  );
                } else if (!snapshot.hasData) {
                  return Center(
                    child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                  );
                }

                final image = snapshot.data!;
                final mediaSize = MediaQuery.of(context).size;
                double maxWidth = mediaSize.width * 0.7;
                double maxHeight = mediaSize.height * 0.7;
                double boxWidth;
                double boxHeight;
                if (image.height * (maxWidth / image.width) <= maxHeight) {
                  boxWidth = maxWidth;
                  boxHeight = image.height * (maxWidth / image.width);
                } else {
                  boxWidth = image.width * (maxHeight / image.height);
                  boxHeight = maxHeight;
                }
                return Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                      border: Border.all(width: 1.0)
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Listener(
                        onPointerDown: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          // find the coordinate
                          final Offset localOffset = box.globalToLocal(details.position);
                          final posX = localOffset.dx;
                          final posY = localOffset.dy;
                          setState(() {
                            // debugPrint("click at: $posX;$posY");
                            clickPosition = normalizePosition(posX, posY, boxWidth, boxHeight);
                            if (!answerStart) {
                              trySetAnswerTime(
                                  result, timeLimitCountDown!.timePassed);
                              answerStart = true;
                            }
                          });
                        },
                        child: questionImage,
                      ),
                      ...(clickPosition == null ? [] : [Positioned(
                        left: clickPosition!.first * boxWidth - 9,
                        top: clickPosition!.last * boxHeight - 9,
                        width: 18,
                        height: 18,
                        // child: Text("${(e.first * 1000).roundToDouble() / 1000};${(e.last * 1000).roundToDouble() / 1000}",)
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                              child: Icon(Icons.circle_rounded, color: Colors.green, size: 12.0,)
                          ),
                        ),
                      )]),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
