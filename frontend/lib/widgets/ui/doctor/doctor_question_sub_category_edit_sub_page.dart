import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/sub_category.dart';
import '../../../utils/common_widget_function.dart';
import 'doctor_exam_edit.dart';
import 'doctor_exam_edit_dialogs.dart';

class QuestionSubCategoryEditSubPage extends StatefulWidget {
  final QuestionSubCategory subCategory;
  final int categoryIndex;
  final int subCategoryIndex;
  final DoctorExamEditPageState _parentState;

  QuestionSubCategoryEditSubPage(this.subCategory, {super.key, required this.categoryIndex, required this.subCategoryIndex, required State parentState})
    : assert(parentState.runtimeType == DoctorExamEditPageState),
      _parentState = parentState as DoctorExamEditPageState;


  @override
  State<QuestionSubCategoryEditSubPage> createState() =>
      _QuestionSubCategoryEditSubPageState();
}

class _QuestionSubCategoryEditSubPageState extends State<QuestionSubCategoryEditSubPage> with UseCommonStyles {
  double listTileCommonHeight = 24;

  TextEditingController descController = TextEditingController(text: "");
  /// 等同于[widget.subCategory]
  late QuestionSubCategory currSubCategory;
  bool editingDesc = false;

  void _resetState() {
    _disableDescInput();
    currSubCategory = widget.subCategory;
    descController = TextEditingController(text: "");
  }

  void _enableDescInput () {
    editingDesc = true;
    widget._parentState.editingItem = true;
    descController.text = currSubCategory.description;
  }

  void _disableDescInput () {
    editingDesc = false;
    widget._parentState.editingItem = false;
  }

  @override
  void initState() {
    _resetState();
    super.initState();
  }

  void _showSubCategoryRuleEditDialog({
    required BuildContext context,
    required ExamState examState,
    required int categoryIndex,
    required int subCategoryIndex,
    int? ruleIndex,
  }) {
    showDialog(context: context, builder: (context) {
      return SubCategoryEvalRuleEditDialog(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, ruleIndex: ruleIndex, examState: examState,);
    });
  }

  void _showSubCategoryTerminateRuleEditDialog({
    required BuildContext context,
    required ExamState examState,
    required int categoryIndex,
    required int subCategoryIndex,
    int? ruleIndex,
  }) {
    showDialog(context: context, builder: (context) {
      return SubCategoryTerminateRuleEditDialog(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, ruleIndex: ruleIndex, examState: examState,);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subCategory != currSubCategory) {
      _resetState();
    }

    ExamState examState = context.watch<ExamState>();

    commonStyles = initStyles(context);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var minHeight = 400.0;
          var minWidth = 600.0;

          ScrollController verticalScrollCtrl = ScrollController();
          ScrollController horizontalScrollCtrl = ScrollController();
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
                                child: Text("套题子项：",
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

                                                completeEditAction() {
                                                  examState.updateSubCategory(
                                                      updatedSubCategory: widget.subCategory,
                                                      categoryIndex: widget.categoryIndex,
                                                      subCategoryIndex: widget.subCategoryIndex).then((_) {
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
                                                          widget.subCategory.description = newVal;
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
                                                  descWidget = Text(widget.subCategory.description, style: commonStyles?.bodyStyle,);
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
                                                    Text("子项名称：",style: commonStyles?.bodyStyle,),
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
                                      child: Container (
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
                                                        children: widget.subCategory.evalRules.asMap().entries
                                                            .map((e) =>
                                                            ListTile(
                                                              title: buildListTileContentWithActionButtons(
                                                                body: Text("${e.key+1}. ${e.value.displayName()}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                                firstBtnAction: () {
                                                                  _showSubCategoryRuleEditDialog(
                                                                    context: context,
                                                                    examState: examState,
                                                                    categoryIndex: widget.categoryIndex,
                                                                    subCategoryIndex: widget.subCategoryIndex,
                                                                    ruleIndex: e.key
                                                                  );
                                                                },
                                                                // 子项只有一种评分规则，所以暂不增删评分规则
                                                                // secondBtnAction: () {
                                                                //   examState.deleteSubCategoryEvalRule(
                                                                //     categoryIndex: widget.categoryIndex,
                                                                //     subCategoryIndex: widget.subCategoryIndex,
                                                                //     ruleIndex: e.key,
                                                                //   );
                                                                // },
                                                                // secondBtnTooltipMsg: "删除",
                                                                // secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
                                                                textAreaMaxHeight: listTileCommonHeight,
                                                                textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                                commonStyles: commonStyles,
                                                                firstBtnTooltipMsg: '编辑',
                                                                firstBtnIcon: const Icon(Icons.edit),
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
                                                    if (currSubCategory.evalRules.isEmpty) {
                                                      button = ElevatedButton(
                                                        onPressed: () {
                                                          _showSubCategoryRuleEditDialog(
                                                            context: context,
                                                            examState: examState,
                                                            categoryIndex: widget.categoryIndex,
                                                            subCategoryIndex: widget.subCategoryIndex,
                                                          );
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
                                            Text("终止规则列表", style: commonStyles?.bodyStyle,),
                                            const Divider(),
                                            Expanded(
                                                child: LayoutBuilder(
                                                    builder: (BuildContext context, BoxConstraints constraints) {
                                                      return ListView(
                                                        children: widget.subCategory.terminateRules.asMap().entries
                                                            .map((e) =>
                                                            ListTile(
                                                              title: buildListTileContentWithActionButtons(
                                                                body: Text("${e.key+1}. ${e.value.displayName()}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                                firstBtnAction: () {
                                                                  _showSubCategoryTerminateRuleEditDialog(
                                                                    context: context,
                                                                    examState: examState,
                                                                    categoryIndex: widget.categoryIndex,
                                                                    subCategoryIndex: widget.subCategoryIndex,
                                                                    ruleIndex: e.key
                                                                  );
                                                                },
                                                                secondBtnAction: () {
                                                                  examState.deleteSubCategoryTerminateRule(
                                                                    categoryIndex: widget.categoryIndex,
                                                                    subCategoryIndex: widget.subCategoryIndex,
                                                                    ruleIndex: e.key
                                                                  ).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                                },
                                                                textAreaMaxHeight: listTileCommonHeight,
                                                                textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                                commonStyles: commonStyles,
                                                                firstBtnTooltipMsg: '编辑',
                                                                firstBtnIcon: const Icon(Icons.edit),
                                                                secondBtnTooltipMsg: "删除",
                                                                secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
                                                              ),
                                                            )).toList(),
                                                      );
                                                    }
                                                )
                                            ),
                                            const Divider(),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _showSubCategoryTerminateRuleEditDialog(
                                                          context: context,
                                                          examState: examState,
                                                          categoryIndex: widget.categoryIndex,
                                                          subCategoryIndex: widget.subCategoryIndex,
                                                      );
                                                    },
                                                    child: Text("新增规则",
                                                    style: commonStyles?.bodyStyle,),
                                                  ),
                                                ],
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
                                            Text("题目列表", style: commonStyles?.bodyStyle,),
                                            const Divider(),
                                            Expanded(
                                                child: LayoutBuilder(
                                                    builder: (BuildContext context, BoxConstraints constraints) {
                                                      return ListView.builder(
                                                        itemBuilder: (BuildContext context, int index) {
                                                          var question = widget.subCategory.questions[index];
                                                          return ListTile(
                                                            key: Key(index.toString()),
                                                            title: buildListTileContentWithActionButtons(
                                                                body: Text("${index+1}. ${question.alias}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                                firstBtnAction: () {
                                                                  if (index > 0) {
                                                                    examState
                                                                        .moveQuestionUp(
                                                                        categoryIndex: widget.categoryIndex,
                                                                        subCategoryIndex: widget.subCategoryIndex,
                                                                        questionIndex: index).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                                  }
                                                                },
                                                                firstBtnTooltipMsg: "上移",
                                                                firstBtnIcon: const Icon(Icons.arrow_upward),
                                                                secondBtnAction: () {
                                                                  if (index < currSubCategory.questions.length - 1) {
                                                                    examState
                                                                        .moveQuestionDown(
                                                                        categoryIndex: widget.categoryIndex,
                                                                        subCategoryIndex: widget.subCategoryIndex,
                                                                        questionIndex: index).catchError((err) { requestResultErrorHandler(context, error: err); return err;});;
                                                                  }
                                                                },
                                                                secondBtnTooltipMsg: "下移",
                                                                secondBtnIcon: const Icon(Icons.arrow_downward),
                                                                textAreaMaxHeight: listTileCommonHeight,
                                                                textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                                commonStyles: commonStyles),
                                                          );
                                                        },
                                                        itemCount: widget.subCategory.questions.length,
                                                      );
                                                    }
                                                )
                                            ),
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
