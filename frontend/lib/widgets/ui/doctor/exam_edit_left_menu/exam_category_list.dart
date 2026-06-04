import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/common_widget_function.dart';
import 'sub_category_list.dart';

/// 左栏菜单树的最外层："套题目录" ExpansionTile + 每个 category 的 ExpansionTile
/// + "新增亚项"按钮；每个 category 的 ExpansionTile 内部嵌 [SubCategoryList]。
/// 从原 [DoctorExamEditPageState._buildQuestionTile] 整段抽出，行为零变更。
/// T6 阶段（#14b）。
///
/// 状态读写：
/// - `context.watch<ExamState>()`: category 列表来源；`examState.deleteCategory`
///   会 notify，由 watch 接住。
/// - `context.watch<ExamEditSelectionState>()`: 渲染 category tile 的"编辑中"
///   指示符（`notEditCurrentTile`）必须随选中态变化重画。
/// - `editingExam.addCategory` 直接调 model 不 notify ExamState；本 widget
///   自身 setState 局部刷新（同 [QuestionList] / [SubCategoryList] 处理）。
/// - 删除 category 调 `selectionState.onCategoryDeleted(i)`——把原父 setState
///   内联的 index 调整搬到 ChangeNotifier 上；T6 阶段方法体保留**逐字行为**，
///   T8 单测时一并审视。
class ExamCategoryList extends StatefulWidget {
  final CommonStyles commonStyles;
  final double listTileCommonHeight;
  final double listTilePaddingBase;
  final double tileContentWidth;

  const ExamCategoryList({
    super.key,
    required this.commonStyles,
    required this.listTileCommonHeight,
    required this.listTilePaddingBase,
    required this.tileContentWidth,
  });

  @override
  State<ExamCategoryList> createState() => _ExamCategoryListState();
}

class _ExamCategoryListState extends State<ExamCategoryList> {
  @override
  Widget build(BuildContext context) {
    var examState = context.watch<ExamState>();
    var selectionState = context.watch<ExamEditSelectionState>();
    var editingExam = examState.exam;
    var commonStyles = widget.commonStyles;

    var categoryWidgets = <Widget>[];

    for (int i = 0; i < editingExam.categories.length; i++) {
      var category = editingExam.categories[i];
      var categoryIndex = i;

      bool notEditCurrentTile = selectionState.editCategoryIndex != i ||
          selectionState.editItem.runtimeType != QuestionCategory;

      categoryWidgets.add(ExpansionTile(
        backgroundColor: commonStyles.theme.focusColor,
        key: Key("category$categoryIndex"),
        tilePadding: EdgeInsets.only(left: 4 * widget.listTilePaddingBase),
        controlAffinity: ListTileControlAffinity.leading,
        title: buildListTileContentWithActionButtons(
            body: Text(category.description,
                style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
            textAreaMaxHeight: widget.listTileCommonHeight,
            textAreaMaxWidth: widget.tileContentWidth,
            commonStyles: commonStyles,
            firstBtnIcon: notEditCurrentTile
                ? const Icon(Icons.edit)
                : Icon(Icons.edit_document, color: commonStyles.primaryColor),
            firstBtnTooltipMsg: notEditCurrentTile ? "编辑" : "编辑中",
            firstBtnAction: notEditCurrentTile
                ? () {
                    continueAction() {
                      selectionState.editItem = category;
                      selectionState.editCategoryIndex = categoryIndex;
                    }

                    if (selectionState.editingItem) {
                      confirm(context,
                          title: "确认",
                          body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开亚项编辑页面？",
                          commonStyles: commonStyles,
                          onConfirm: (dialogCtx) {
                            continueAction();
                            Navigator.pop(dialogCtx);
                          });
                    } else {
                      continueAction();
                    }
                  }
                : null,
            secondBtnIcon:
                Icon(Icons.delete_outline, color: commonStyles.errorColor),
            secondBtnTooltipMsg: "删除",
            secondBtnAction: () {
              confirm(context,
                  title: '删除亚项',
                  body: '确认要删除亚项："${category.description}" 吗，删除后不可恢复',
                  commonStyles: commonStyles,
                  onConfirm: (dialogCtx) {
                    examState
                        .deleteCategory(categoryIndex: categoryIndex)
                        .then((_) {
                      selectionState.onCategoryDeleted(categoryIndex);
                      Navigator.pop(dialogCtx);
                    }).catchError((err) {
                      requestResultErrorHandler(context, error: err);
                      return err;
                    });
                  });
            }),
        children: [
          // _buildCategoryRuleTile(),
          SubCategoryList(
            categoryIndex: categoryIndex,
            commonStyles: commonStyles,
            listTileCommonHeight: widget.listTileCommonHeight,
            listTilePaddingBase: widget.listTilePaddingBase,
            tileContentWidth: widget.tileContentWidth,
          ),
        ],
      ));
    }

    categoryWidgets.insert(0, Align(
      alignment: Alignment.center,
      child: _buildNewItemButton("新增亚项", onPressed: () {
        commonAction(BuildContext? dialogCtx) {
          editingExam.addCategory().then((category) {
            setState(() {
              selectionState.editItem = category;
              selectionState.editCategoryIndex =
                  editingExam.categories.length - 1;
            });
            if (dialogCtx != null) Navigator.pop(dialogCtx);
          }).catchError((err) {
            requestResultErrorHandler(context, error: err);
            return err;
          });
        }

        if (selectionState.editingItem) {
          confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开新增亚项页面？",
              commonStyles: commonStyles,
              onConfirm: (dialogCtx) {
                commonAction(dialogCtx);
              });
        } else {
          commonAction(null);
        }
      }),
    ));

    // 注：原 prod 这里有两次 `categoryWidgets.isEmpty ? [Text("无")] : categoryWidgets`
    // 的兜底判断。但 insert(0, ...) 之后 categoryWidgets 至少有一个元素（"新增亚项"
    // 按钮），isEmpty 永远为 false，两次判断都是死分支。T6 保留语义不变（仍走"非空"
    // 分支），不顺手清理死代码，避免行为变化引入争议。

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: widget.listTilePaddingBase),
      initiallyExpanded: true,
      title: buildListTileContentWithActionButtons(
        body: Text("套题目录",
            style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
        textAreaMaxHeight: widget.listTileCommonHeight,
        textAreaMaxWidth: widget.tileContentWidth + 60,
        commonStyles: commonStyles,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      children: categoryWidgets,
    );
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
