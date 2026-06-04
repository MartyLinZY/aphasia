import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/common_widget_function.dart';
import 'question_list.dart';

/// 左栏菜单树的中间层：渲染某个 category 下所有 subCategory 的 ExpansionTile
/// 与"新增子项"按钮，每个 ExpansionTile 内部嵌 [QuestionList]。从原
/// [DoctorExamEditPageState._buildQuestionTile] 的中间 `for j` 循环原样抽出，
/// 行为零变更。T5 阶段（#14b）。
///
/// 状态读写：
/// - `context.watch<ExamState>()`: subCategory 列表来源；`examState.deleteSubCategory`
///   会 notify，由 watch 接住。
/// - `context.watch<ExamEditSelectionState>()`: 渲染 subCategory tile 的"编辑中"
///   指示符（`editCurrentTile`）必须随选中态变化重画。
/// - `editingExam.addSubCategory` 直接调 model 不 notify ExamState，本 widget
///   自身 setState 局部刷新（与 [QuestionList] 同样处理路径）。
/// - 删除 subCategory 调 `selectionState.onSubCategoryDeleted(i, j)`——这一层
///   把原父 setState 内联的 index 调整搬到 ChangeNotifier 上；T5 阶段方法体
///   保留**逐字行为**（含 `:583` 历史 i/j bug），T8 修。
class SubCategoryList extends StatefulWidget {
  final int categoryIndex;
  final CommonStyles commonStyles;
  final double listTileCommonHeight;
  final double listTilePaddingBase;
  final double tileContentWidth;

  const SubCategoryList({
    super.key,
    required this.categoryIndex,
    required this.commonStyles,
    required this.listTileCommonHeight,
    required this.listTilePaddingBase,
    required this.tileContentWidth,
  });

  @override
  State<SubCategoryList> createState() => _SubCategoryListState();
}

class _SubCategoryListState extends State<SubCategoryList> {
  @override
  Widget build(BuildContext context) {
    var examState = context.watch<ExamState>();
    var selectionState = context.watch<ExamEditSelectionState>();
    var editingExam = examState.exam;
    var i = widget.categoryIndex;
    var category = editingExam.categories[i];
    var commonStyles = widget.commonStyles;

    var children = <Widget>[];

    children.add(Align(
      alignment: Alignment.center,
      child: _buildNewItemButton("新增子项", onPressed: () {
        commonAction(BuildContext? dialogCtx) {
          editingExam.addSubCategory(categoryIndex: i).then((subCate) {
            setState(() {
              selectionState.editItem = subCate;
              selectionState.editCategoryIndex = i;
              selectionState.editSubCategoryIndex =
                  editingExam.categories[i].subCategories.length - 1;
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
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开子项新增页？",
              commonStyles: commonStyles,
              onConfirm: (dialogCtx) {
                commonAction(dialogCtx);
              });
        } else {
          commonAction(null);
        }
      }),
    ));

    for (int j = 0; j < category.subCategories.length; j++) {
      var subCategory = category.subCategories[j];
      var subCategoryIndex = j;

      bool editCurrentTile = selectionState.editCategoryIndex == i &&
          selectionState.editSubCategoryIndex == j &&
          selectionState.editItem.runtimeType == QuestionSubCategory;

      children.add(ExpansionTile(
        backgroundColor: commonStyles.theme.focusColor.withAlpha(40),
        tilePadding: EdgeInsets.only(left: 7 * widget.listTilePaddingBase),
        controlAffinity: ListTileControlAffinity.leading,
        title: buildListTileContentWithActionButtons(
          body: Text(subCategory.description,
              style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
          textAreaMaxHeight: widget.listTileCommonHeight,
          textAreaMaxWidth: widget.tileContentWidth,
          commonStyles: commonStyles,
          firstBtnIcon: editCurrentTile
              ? Icon(Icons.edit_document, color: commonStyles.primaryColor)
              : const Icon(Icons.edit),
          firstBtnTooltipMsg: editCurrentTile ? "编辑中" : "编辑",
          firstBtnAction: editCurrentTile
              ? null
              : () {
                  continueAction() {
                    selectionState.editItem = subCategory;
                    selectionState.editCategoryIndex = i;
                    selectionState.editSubCategoryIndex = subCategoryIndex;
                  }

                  if (selectionState.editingItem) {
                    confirm(context,
                        title: "确认",
                        body: '当前有未保存的编辑内容，是否丢弃这些内容并继续打开子项编辑页面？',
                        commonStyles: commonStyles,
                        onConfirm: (dialogCtx) {
                          continueAction();
                          Navigator.pop(dialogCtx);
                        });
                  } else {
                    continueAction();
                  }
                },
          secondBtnIcon:
              Icon(Icons.delete_outline, color: commonStyles.errorColor),
          secondBtnTooltipMsg: "删除",
          secondBtnAction: () {
            confirm(context,
                title: "删除子项",
                body: '确认要删除子项："${subCategory.description}" 吗，删除后不可恢复。',
                commonStyles: commonStyles,
                onConfirm: (dialogCtx) {
                  examState
                      .deleteSubCategory(
                          categoryIndex: i, subCategoryIndex: subCategoryIndex)
                      .then((_) {
                    Navigator.pop(dialogCtx);
                    selectionState.onSubCategoryDeleted(i, subCategoryIndex);
                  }).catchError((err) {
                    requestResultErrorHandler(context, error: err);
                    return err;
                  });
                });
          },
        ),
        children: [
          QuestionList(
            categoryIndex: i,
            subCategoryIndex: subCategoryIndex,
            commonStyles: commonStyles,
            listTileCommonHeight: widget.listTileCommonHeight,
            listTilePaddingBase: widget.listTilePaddingBase,
            tileContentWidth: widget.tileContentWidth,
          ),
        ],
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
