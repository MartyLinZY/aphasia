import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';

class QuestionTypeStep extends StatelessWidget {
  static const Map<Type, String> _questionIntroduction = {
    AudioQuestion: "录音作答题：患者通过录音作答。可选择关键词，关键词列表，流畅度分析等方式对患者作答评分。",
    ChoiceQuestion: "选择题：患者通过点击选项作答。可设置2-20个选项。",
    CommandQuestion: "指令题：患者通过点击或拖动物体作答。可设置多个物体并设置指令，系统按照患者完成指令的程度打分。",
    WritingQuestion: "书写题：患者通过手写作答。可以设置关键词或关键词列表，系统自动识别患者手写内容并与关键词进行匹配打分。",
    ItemFindingQuestion: "场景寻物题：在题目图片中圈出物体，患者通过点击图片作答，系统自动判断患者是否正确点击指定物体",
  };

  final Type currentType;
  final ValueChanged<Type> onTypeSelected;
  final CommonStyles commonStyles;
  final double cardElevation;

  const QuestionTypeStep({
    super.key,
    required this.currentType,
    required this.onTypeSelected,
    required this.commonStyles,
    required this.cardElevation,
  });

  @override
  Widget build(BuildContext context) {
    return wrappedByCard(
      elevation: cardElevation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("选择题目类型：", style: commonStyles.titleStyle),
          const Divider(height: 24, thickness: 0.5),
          Row(
            children: [
              Text("题目类型：", style: commonStyles.bodyStyle),
              DropdownMenu(
                initialSelection: currentType,
                requestFocusOnTap: false,
                enableSearch: false,
                onSelected: (Type? value) {
                  assert(value != null);
                  onTypeSelected(value!);
                },
                textStyle: commonStyles.bodyStyle,
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: AudioQuestion, label: AudioQuestion.questionTypeName()),
                  DropdownMenuEntry(value: ChoiceQuestion, label: ChoiceQuestion.questionTypeName()),
                  DropdownMenuEntry(value: CommandQuestion, label: CommandQuestion.questionTypeName()),
                  DropdownMenuEntry(value: WritingQuestion, label: WritingQuestion.questionTypeName()),
                  DropdownMenuEntry(value: ItemFindingQuestion, label: ItemFindingQuestion.questionTypeName()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "题型简介：${_questionIntroduction[currentType]!}",
                  style: commonStyles.bodyStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
