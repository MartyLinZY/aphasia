
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../models/result/results.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';

class ChoiceQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const ChoiceQuestionAnswerArea(
      {super.key,
        required this.question,
        required this.commonStyles,
        required this.goToNextQuestion});

  @override
  State<ChoiceQuestionAnswerArea> createState() =>
      _AudioQuestionAnswerAreaState();
}

class _AudioQuestionAnswerAreaState extends State<ChoiceQuestionAnswerArea>
    with QuestionAnswerArea
    implements ResettableState {

  // 常规变量
  late ChoiceQuestion currQuestion;
  late ChoiceQuestionResult result;

  List<int> choiceSelected = [];

  @override
  void resetState() {
    currQuestion = widget.question as ChoiceQuestion;
    result = ChoiceQuestionResult(sourceQuestion: widget.question);
    choiceSelected = [];

    initQuestionStem(currQuestion);
  }

  @override
  void finishAnswer() {
    doCommonFinishStep(result);

    evalQuestion(choiceSelected: choiceSelected, result: result, question: currQuestion);
  }

  void evalQuestion({required List<int> choiceSelected, required ChoiceQuestion question, required ChoiceQuestionResult result}) {
    result.choiceSelected = choiceSelected;

    doEvalQuestion(question: question, result: result, goToNextQuestion: widget.goToNextQuestion);
  }

  @override
  void resetAnswerStateAfterHint(QuestionEvalRule rule) {}

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
        child: _buildChoices(context, commonStyles: commonStyles, question: currQuestion),
      ));
    }

    Widget actionArea = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () {
              finishAnswer();
            },
            child: Text(
              "选好了",
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

  Widget _buildChoices(BuildContext context, {required Question question, CommonStyles? commonStyles}) {
    question = question as ChoiceQuestion;
    EvalChoiceQuestionByCorrectChoiceCount evalRule = question.evalRule! as EvalChoiceQuestionByCorrectChoiceCount;

    final media = MediaQuery.of(context);
    var screenAspectRatio = media.size.aspectRatio + 0.3;

    int crossAxisCount;
    if (evalRule.choices.length <= 4) {
      crossAxisCount = 2;
    } else if (evalRule.choices.length <= 9) {
      crossAxisCount = 3;
    } else if (evalRule.choices.length <= 12) {
      crossAxisCount = 4;
    } else if (evalRule.choices.length <= 20) {
      crossAxisCount = 5;
    } else {
      throw UnimplementedError("预期外的错误，超过了20个选项");
    }

    return GridView.count(
      mainAxisSpacing: 4.0,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 4.0,
      childAspectRatio: screenAspectRatio,
      shrinkWrap: true,
      children: evalRule.choices.asMap().entries.map((e) {
        int index = e.key;
        Choice choice = e.value;

        int indexInSelected = choiceSelected.indexOf(index);

        bool isSingleChoose = evalRule.correctChoices.length == 1;

        return InkWell(
          onTap: () {
            setState(() {
              if (isSingleChoose) {
                choiceSelected.clear();
                choiceSelected.add(index);
              } else {
                if (choiceSelected.contains(index)) {
                  choiceSelected.remove(index);
                } else {
                  choiceSelected.add(index);
                }
              }
            });
          },
          child: Stack(
            children: [
              Center(
                child: buildUrlOrAssetsImage(context,
                  imageUrl: choice.imageUrlOrPath!,
                  commonStyles: commonStyles
                ),
              ),
              Center(
                child: indexInSelected == -1
                    ? const SizedBox.shrink()
                    : Container(
                  decoration: BoxDecoration(
                    color: commonStyles?.primaryColor,
                    shape: BoxShape.circle
                  ),
                  width: 32,
                  height: 32,
                  child: isSingleChoose
                      ? Icon(Icons.check_circle_outline, color: commonStyles?.onPrimaryColor, size: 32,)
                      : Center(child: Text("${indexInSelected+1}", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles.onPrimaryColor),)),
                ),
              )
            ],
          )
        );
      }).toList(),
    );
  }

}
