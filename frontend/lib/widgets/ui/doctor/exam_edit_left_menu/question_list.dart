import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/common_widget_function.dart';
import '../doctor_exam_question_edit.dart';

/// 左栏菜单树的最内层：渲染某个 subCategory 下的所有题目 ListTile 与"新增题目"
/// 按钮。从 [DoctorExamEditPageState._buildQuestionTile] 的最内 `for k` 循环原样
/// 抽出，行为零变更。T4 阶段（#14b）。
///
/// 状态读写：
/// - 题目列表读自 `context.watch<ExamState>().exam.categories[i].subCategories[j]`；
///   `examState.deleteQuestion` 会 `notifyListeners()`，由 watch 接住自动 rebuild。
/// - `editingExam.addQuestion / updateQuestion` 直接调 model，不 notify ExamState；
///   原 prod 靠父 `setState` 触发左栏整体 rebuild。本 widget 改用自身 `setState` 局
///   部刷新即可（父 State 不再依赖 question 数量变化）。
/// - 选中态写到 [ExamEditSelectionState]：用户从某题目编辑页返回 / 新增题目后，
///   editItem 切换到当前 subCategory；写动作走 ChangeNotifier `_safeNotify` 链路。
class QuestionList extends StatefulWidget {
  final int categoryIndex;
  final int subCategoryIndex;
  final CommonStyles commonStyles;
  final double listTileCommonHeight;
  final double listTilePaddingBase;
  final double tileContentWidth;

  const QuestionList({
    super.key,
    required this.categoryIndex,
    required this.subCategoryIndex,
    required this.commonStyles,
    required this.listTileCommonHeight,
    required this.listTilePaddingBase,
    required this.tileContentWidth,
  });

  @override
  State<QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends State<QuestionList> {
  @override
  Widget build(BuildContext context) {
    var examState = context.watch<ExamState>();
    var editingExam = examState.exam;
    var subCategory = editingExam
        .categories[widget.categoryIndex].subCategories[widget.subCategoryIndex];
    var selectionState = context.read<ExamEditSelectionState>();
    var commonStyles = widget.commonStyles;

    var children = <Widget>[];

    children.add(Align(
      alignment: Alignment.center,
      child: _buildNewItemButton("新增题目", onPressed: () {
        commonAction() {
          Navigator.push<Question?>(context,
                  MaterialPageRoute(builder: (context) => const DoctorExamQuestionEditPage()))
              .then((newQuestion) {
            if (newQuestion != null) {
              editingExam
                  .addQuestion(newQuestion,
                      categoryIndex: widget.categoryIndex,
                      subCategoryIndex: widget.subCategoryIndex)
                  .then((addedQuestion) {
                setState(() {
                  selectionState.editItem = editingExam
                      .categories[widget.categoryIndex]
                      .subCategories[widget.subCategoryIndex];
                  selectionState.editCategoryIndex = widget.categoryIndex;
                  selectionState.editSubCategoryIndex = widget.subCategoryIndex;
                });
              }).catchError((err) {
                requestResultErrorHandler(context, error: err);
                return err;
              });
            }
          });
        }

        if (selectionState.editingItem) {
          confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开新增题目页面？",
              commonStyles: commonStyles,
              onConfirm: (context) {
                Navigator.pop(context);
                commonAction();
              });
        } else {
          commonAction();
        }
      }),
    ));

    for (int k = 0; k < subCategory.questions.length; k++) {
      var question = subCategory.questions[k];
      var questionIndex = k;
      children.add(ListTile(
        contentPadding: EdgeInsets.only(left: 10 * widget.listTilePaddingBase),
        title: buildListTileContentWithActionButtons(
          body: Text(question.alias ?? question.defaultQuestionName(),
              style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
          firstBtnAction: () {
            continueAction() {
              Navigator.push<Question>(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DoctorExamQuestionEditPage(question: question)))
                  .then((updated) {
                if (updated != null) {
                  editingExam
                      .updateQuestion(updated,
                          categoryIndex: widget.categoryIndex,
                          subCategoryIndex: widget.subCategoryIndex,
                          questionIndex: questionIndex)
                      .then((value) {
                    setState(() {
                      selectionState.editItem = editingExam
                          .categories[widget.categoryIndex]
                          .subCategories[widget.subCategoryIndex];
                      selectionState.editCategoryIndex = widget.categoryIndex;
                      selectionState.editSubCategoryIndex =
                          widget.subCategoryIndex;
                    });
                  }).catchError((err) {
                    requestResultErrorHandler(context, error: err);
                    return err;
                  });
                }
              });
            }

            if (selectionState.editingItem) {
              confirm(context,
                  title: "确认",
                  body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开题目编辑页面？",
                  commonStyles: commonStyles,
                  onConfirm: (context) {
                    Navigator.pop(context);
                    continueAction();
                  });
            } else {
              continueAction();
            }
          },
          firstBtnTooltipMsg: "查看（编辑）题目详情",
          firstBtnIcon: const Icon(Icons.edit),
          secondBtnAction: () {
            confirm(context,
                title: '删除问题',
                body:
                    '确认要删除问题："${question.alias ?? question.defaultQuestionName()}" 吗，删除后不可恢复',
                commonStyles: commonStyles,
                onConfirm: (context) {
                  Navigator.pop(context);
                  examState
                      .deleteQuestion(
                          categoryIndex: widget.categoryIndex,
                          subCategoryIndex: widget.subCategoryIndex,
                          questionIndex: questionIndex)
                      .catchError((err) {
                    requestResultErrorHandler(context, error: err);
                    return err;
                  });
                });
          },
          secondBtnTooltipMsg: "删除",
          secondBtnIcon:
              Icon(Icons.delete_outline, color: commonStyles.errorColor),
          textAreaMaxHeight: widget.listTileCommonHeight,
          textAreaMaxWidth: widget.tileContentWidth,
          commonStyles: commonStyles,
        ),
      ));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  TextButton _buildNewItemButton(String text,
      {required void Function() onPressed}) {
    return TextButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add),
            Text(text,
                style: widget.commonStyles.bodyStyle,
                overflow: TextOverflow.ellipsis),
          ],
        ));
  }
}
