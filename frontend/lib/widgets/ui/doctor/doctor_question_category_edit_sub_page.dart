import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/category.dart';
import '../../../utils/common_widget_function.dart';

class QuestionCategoryEditSubPage extends StatefulWidget {
  final QuestionCategory category;
  final int categoryIndex;

  const QuestionCategoryEditSubPage(this.category, {super.key, required this.categoryIndex});

  @override
  State<QuestionCategoryEditSubPage> createState() => _QuestionCategoryEditSubPageState();
}

class _QuestionCategoryEditSubPageState extends State<QuestionCategoryEditSubPage> with UseCommonStyles {
  double listTileCommonHeight = 24;

  TextEditingController descController = TextEditingController(text: "");
  late QuestionCategory currCategory;
  bool editingDesc = false;

  void _resetState() {
    _disableDescInput();
    currCategory = widget.category;
    descController = TextEditingController(text: "");
  }

  @override
  void initState() {
    _resetState();
    super.initState();
  }

  void _enableDescInput () {
    editingDesc = true;
    context.read<ExamEditSelectionState>().editingItem = true;
    descController.text = currCategory.description;
  }

  void _disableDescInput () {
    editingDesc = false;
    context.read<ExamEditSelectionState>().editingItem = false;
  }

  void _showCategoryRuleEditDialog({
    required BuildContext context,
    required ExamState examState,
    required int categoryIndex,
    int? ruleIndex,
  }) {
    ExamCategoryEvalRule rule = ruleIndex == null ? EvalBySubCategoryScoreSum(): examState.exam.categories[categoryIndex].rules[ruleIndex].copy();
    showDialog(context: context, builder: (context) {
      Widget body;
      switch (rule.runtimeType) {
        case EvalBySubCategoryScoreSum:
          body = Text("该规则无可修改属性", style: commonStyles?.bodyStyle,);
          break;
        default:
          throw UnimplementedError();
      }

      return buildSimpleActionDialog(context,
        title: "亚项评分规则",
        body: body,
        commonStyles: commonStyles,
        onConfirm: (context) {
          if (ruleIndex == null) {
            examState.addCategoryEvalRule(categoryIndex: categoryIndex, newRule: rule).then((_) {
              Navigator.pop(context);
            }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
          } else {
            examState.updateCategoryEvalRule(categoryIndex: categoryIndex, updatedEvalRule: rule, ruleIndex: ruleIndex).then((_) {
              Navigator.pop(context);
            }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
          }
        }
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category != currCategory) {
      _resetState();
    }

    commonStyles = initStyles(context);
    ExamState examState = context.watch<ExamState>();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var minHeight = 400.0;
        var minWidth = 600.0;

        var horizontalScrollCtrl = ScrollController();
        var verticalScrollCtrl = ScrollController();
        return Scrollbar(
          controller: horizontalScrollCtrl,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalScrollCtrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                  maxWidth: constraints.maxWidth < minWidth? minWidth : constraints.maxWidth
              ),
              child: Scrollbar(
                controller: verticalScrollCtrl,
                child: SingleChildScrollView(
                  controller: verticalScrollCtrl,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: minWidth,
                        minHeight: minHeight,
                        maxHeight: constraints.maxHeight < minHeight? minHeight : constraints.maxHeight
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("套题亚项：",
                                style: commonStyles?.titleStyle,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Builder(
                                            builder: (context) {
                                              Widget descWidget;
                                              Widget actionBtn;

                                              completeEditAction () {
                                                examState.updateCategory(updatedCategory: widget.category, categoryIndex: widget.categoryIndex).then((_) {
                                                  setState(() {
                                                    _disableDescInput();
                                                  });
                                                }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                              }

                                              if (editingDesc) {
                                                descWidget = Container(
                                                  constraints: const BoxConstraints(maxWidth: 200, minWidth: 100),
                                                  child: TextField(
                                                    autofocus: true,
                                                    controller: descController,
                                                    maxLength: 50,
                                                    onChanged: (String newVal) {
                                                      setState(() {
                                                        widget.category.description = newVal;
                                                      });
                                                    },
                                                    onEditingComplete: completeEditAction,
                                                  ),
                                                );
                                                actionBtn = TextButton(
                                                    onPressed: () {
                                                      completeEditAction();
                                                    },
                                                    child: const Icon(Icons.check)
                                                );
                                              } else {
                                                descWidget = Text(widget.category.description, style: commonStyles?.bodyStyle,);
                                                actionBtn = TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _enableDescInput();
                                                      });
                                                    },
                                                    child: const Icon(Icons.edit_outlined)
                                                );
                                              }

                                              return Row(
                                                children: [
                                                  Text("亚项名称：",style: commonStyles?.bodyStyle,),
                                                  descWidget,
                                                  actionBtn
                                                ],
                                              );
                                            }
                                        ),
                                      ),
                                    )
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey)
                                    ),
                                    child: Column(
                                      children: [
                                        Text("计分规则", style: commonStyles?.bodyStyle,),
                                        const Divider(),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return ListView(
                                                children: widget.category.rules.asMap().entries
                                                    .map((e) =>
                                                    ListTile(
                                                      title: buildListTileContentWithActionButtons(
                                                        textAreaMaxHeight: listTileCommonHeight,
                                                        textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                        commonStyles: commonStyles,
                                                        body: Text("${e.key+1}. ${e.value.displayName()}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                        firstBtnAction: () {
                                                          _showCategoryRuleEditDialog(context: context, examState: examState, categoryIndex: widget.categoryIndex, ruleIndex: e.key);
                                                        },
                                                        firstBtnTooltipMsg: '编辑',
                                                        firstBtnIcon: const Icon(Icons.edit),
                                                        // 亚项只有一种评分规则，所以暂不增删评分规则
                                                        // secondBtnAction: () {
                                                        //   // TODO: 二次弹窗确认删除
                                                        //   examState.deleteCategoryEvalRule(categoryIndex: widget.categoryIndex, ruleIndex: e.key,);
                                                        // },
                                                        // secondBtnTooltipMsg: "删除",
                                                        // secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
                                                      ),
                                                    )).toList(),
                                              );
                                            }
                                          )
                                        ),
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Builder(
                                            builder: (context) {
                                              Widget? button;
                                              if (currCategory.rules.isEmpty) {
                                                button = ElevatedButton(
                                                  onPressed: () {
                                                    _showCategoryRuleEditDialog(context: context, examState: examState, categoryIndex: widget.categoryIndex);
                                                  },
                                                  child: Text("新增规则", style: commonStyles?.bodyStyle,),
                                                );
                                              } else {
                                                button = ElevatedButton(
                                                  onPressed: null,
                                                  child: Text("规则已设置", style: commonStyles?.bodyStyle,),
                                                );
                                              }
                                              return Center(child: button,);
                                            }
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ),
                                const SizedBox(width: 16,),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey)
                                    ),
                                    child: Column(
                                      children: [
                                        Text("子项列表", style: commonStyles?.bodyStyle,),
                                        const Divider(),
                                        Expanded(
                                          child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return ListView.builder(
                                                  itemBuilder: (BuildContext context, int index) {
                                                    var subCategory = widget.category.subCategories[index];
                                                    return ListTile(
                                                      key: Key(index.toString()),
                                                      title: buildListTileContentWithActionButtons(
                                                          body: Text("${index+1}. ${subCategory.description}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                          firstBtnAction: () {
                                                            if (index > 0) {
                                                              examState
                                                                  .moveSubCategoryUp(
                                                                  categoryIndex: widget
                                                                      .categoryIndex,
                                                                  subCategoryIndex: index).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                            }
                                                          },
                                                          firstBtnTooltipMsg: "上移",
                                                          firstBtnIcon: const Icon(Icons.arrow_upward),
                                                          secondBtnAction: () {
                                                            if (index < currCategory.subCategories.length - 1) {
                                                              examState
                                                                  .moveSubCategoryDown(
                                                                  categoryIndex: widget
                                                                      .categoryIndex,
                                                                  subCategoryIndex: index).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                            }
                                                          },
                                                          secondBtnTooltipMsg: "下移",
                                                          secondBtnIcon: const Icon(Icons.arrow_downward),
                                                          textAreaMaxHeight: listTileCommonHeight,
                                                          textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                          commonStyles: commonStyles),
                                                    );
                                                  },
                                                  itemCount: widget.category.subCategories.length,
                                                );
                                              }
                                          )
                                        ),
                                        // Padding(
                                        //   padding: const EdgeInsets.all(8.0),
                                        //   child: Row(
                                        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        //     children: [
                                        //       ElevatedButton(onPressed: () {}, child: Text("测试", style: commonStyles?.bodyStyle,)),
                                        //       ElevatedButton(onPressed: () {}, child: Text("测试", style: commonStyles?.bodyStyle,)),
                                        //     ],
                                        //   ),
                                        // )
                                      ],
                                    ),
                                  )
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
