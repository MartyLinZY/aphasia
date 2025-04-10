
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

  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const _choiceAnimationDuration = Duration(milliseconds: 300);

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
                widget.commonStyles?.primaryColor?.withOpacity(0.03) ?? Colors.white,
                widget.commonStyles?.onPrimaryColor?.withOpacity(0.05) ?? Colors.white,
              ]
            ),
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
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildActionArea(commonStyles),
        )
      ],
    );
  }

  Widget _buildQuestionBoard(CommonStyles? commonStyles) {
    if (imageDisplayed) {
      return buildUrlOrAssetsImage(
        context,
        imageUrl: displayImageUrl!,
        commonStyles: commonStyles,
      );
    }
    return _buildChoices(context, commonStyles: commonStyles, question: currQuestion);
  }

  Widget _buildChoices(BuildContext context, {required Question question, CommonStyles? commonStyles}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return GridView.count(
          mainAxisSpacing: 8.0,
          crossAxisCount: _calculateCrossAxisCount(question),
          childAspectRatio: 1.2,
          shrinkWrap: true,
          children: _buildChoiceCards(context, question, screenWidth, commonStyles),
        );
      }
    );
  }

  Widget _buildActionArea(CommonStyles? commonStyles) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: Text("提交答案",
            style: commonStyles?.bodyStyle?.copyWith(
              color: Colors.white,
              fontSize: 16
            )
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: commonStyles?.primaryColor ?? Colors.blueAccent,
            padding: _buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
          ),
          onPressed: finishAnswer,
        ),
        const SizedBox(height: 24),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );
  }

  List<Widget> _buildChoiceCards(BuildContext context, Question question, double screenWidth, CommonStyles? commonStyles) {
    final evalRule = (question as ChoiceQuestion).evalRule as EvalChoiceQuestionByCorrectChoiceCount;
    return evalRule.choices.asMap().entries.map((e) {
      final isSelected = choiceSelected.contains(e.key);
      
      return AnimatedContainer(
        duration: _choiceAnimationDuration,
        margin: EdgeInsets.all(screenWidth > 600 ? 8 : 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? commonStyles?.primaryColor ?? Colors.blue 
              : Colors.transparent,
            width: 2
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: 8,
              offset: Offset(0, isSelected ? 4 : 2)
            )
          ]
        ),
        child: _buildChoiceItem(e.key, e.value, commonStyles),
      );
    }).toList();
  }

  Widget _buildChoiceItem(int index, Choice choice, CommonStyles? commonStyles) {
    return InkWell(
      onTap: () => _handleChoiceSelection(index),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(child: choice.imageUrlOrPath != null 
            ? buildUrlOrAssetsImage(context, 
                imageUrl: choice.imageUrlOrPath!, // 移除非空断言!
                commonStyles: commonStyles
              )
            : const Icon(Icons.error_outline, color: Colors.red) // 添加空路径处理
          ),
          if (choiceSelected.contains(index))
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: commonStyles?.primaryColor,
                shape: BoxShape.circle
              ),
              child: Text(
                "${choiceSelected.indexOf(index) + 1}",
                style: commonStyles?.bodyStyle?.copyWith(
                  color: commonStyles.onPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
            )
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(Question question) {
    final choiceQuestion = question as ChoiceQuestion;
    final evalRule = choiceQuestion.evalRule as EvalChoiceQuestionByCorrectChoiceCount;
    final choiceCount = evalRule.choices.length;
    if (choiceCount <= 4) return 2;
    if (choiceCount <= 9) return 3;
    if (choiceCount <= 12) return 4;
    return 5;
  }

  void _handleChoiceSelection(int index) {
    setState(() {
      if ((currQuestion.evalRule as EvalChoiceQuestionByCorrectChoiceCount).correctChoices.length == 1) {
        choiceSelected = [index];
      } else {
        choiceSelected.contains(index) 
          ? choiceSelected.remove(index)
          : choiceSelected.add(index);
      }
    });
  }
}
