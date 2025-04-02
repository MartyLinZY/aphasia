import 'dart:async';
import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/widgets/ui/common/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/category.dart';
import '../../../models/exam/sub_category.dart';
import '../../../utils/common_widget_function.dart';
import 'doctor_exam_edit_dialogs.dart';
import 'doctor_exam_question_edit.dart';


/// 新建套题引导页
class DoctorExamEditInstructionPage extends StatefulWidget {
  final bool recoveryMode;
  const DoctorExamEditInstructionPage({super.key, this.recoveryMode = false});

  @override
  State<DoctorExamEditInstructionPage> createState() => _DoctorExamEditInstructionPageState();
}

class _DoctorExamEditInstructionPageState extends State<DoctorExamEditInstructionPage> with UseCommonStyles {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameFieldCtrl = TextEditingController();
  TextEditingController descFieldCtrl = TextEditingController();

  TextEditingController templateExamIdField = TextEditingController();

  int currentStep = 0;

  bool isRecovery = false;

  @override
  void initState() {
    super.initState();
    isRecovery = widget.recoveryMode;
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text("创建新套题引导", style: commonStyles?.titleStyle,)),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Stepper(
                // type: StepperType.horizontal,
                // stepIconBuilder: (context, stepState) {
                //
                // },
                controlsBuilder: (context, ctrlDetail) {
                  if (ctrlDetail.currentStep == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("返回", style: commonStyles!.bodyStyle,),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ctrlDetail.onStepContinue!();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                            child: Text("创建", style: commonStyles!.bodyStyle?.copyWith(color: theme.colorScheme.onPrimary),),
                          )
                        ],
                      ),
                    );
                  } else {
                    return const Text("");
                  }
                },
                currentStep: currentStep,
                onStepCancel: () {
                  if (currentStep == 0) {
                    Navigator.pop(context);
                  }
                },
                onStepContinue: () {
                  if (currentStep == 0) {
                    if ( _formKey.currentState!.validate()) {
                      setState(() {
                        currentStep++;

                        ExamQuestionSet
                            .createExam(name: nameFieldCtrl.text, description: descFieldCtrl.text, isRecovery: isRecovery)
                            .then((exam) async {
                          Timer(const Duration(milliseconds: 750),
                                  () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
                                  create: (BuildContext context) => ExamState(exam),
                                  child: const DoctorExamEditPage()
                              ))));
                        });
                      });
                    }
                  }
                },
                onStepTapped: (index) { },
                steps: [
                  // Step(
                  //   title: Text("基本信息", style: commonStyles!.titleStyle,),
                  //   content: Form(
                  //     key: _formKey,
                  //     child: ConstrainedBox(
                  //       constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  //       child: Align(
                  //         heightFactor: 1.0,
                  //         alignment: Alignment.centerLeft,
                  //         child: Column(
                  //           mainAxisSize: MainAxisSize.min,
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text("套题方案名和简介", style: commonStyles!.titleStyle,),
                  //             const SizedBox(
                  //               height: 16,
                  //             ),
                  //             Container(
                  //               constraints: const BoxConstraints(
                  //                   maxWidth: 600
                  //               ),
                  //               child: TextFormField(
                  //                 decoration: const InputDecoration(
                  //                   hintText: "套题方案名称（必填）",
                  //                 ),
                  //                 controller: nameFieldCtrl,
                  //                 validator: (String? value) {
                  //                   if (value == null || value == "") {
                  //                     return "请输入套题方案名称";
                  //                   }
                  //                   return null;
                  //                 },
                  //               ),
                  //             ),
                  //             const SizedBox(
                  //               height: 16,
                  //             ),
                  //             Container(
                  //               constraints: const BoxConstraints(
                  //                   maxWidth: 600
                  //               ),
                  //               child: TextFormField(
                  //                 decoration: const InputDecoration(
                  //                   hintText: "简介",
                  //                 ),
                  //                 controller: descFieldCtrl,
                  //               ),
                  //             ),
                  //             const SizedBox(height: 16,),
                  //             Row(
                  //               children: [
                  //                 Text("是否为康复方案：", style: commonStyles?.bodyStyle),
                  //                 Checkbox(value: isRecovery, onChanged: (bool? value) {
                  //                   setState(() {
                  //                     isRecovery = value ?? false;
                  //                   });
                  //                 }),
                  //               ],
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Step(
                    title: Text("基本信息", style: commonStyles!.titleStyle,),
                    content: Form(
                      key: _formKey,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                        child: Align(
                          heightFactor: 1.0,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("套题方案名和简介", style: commonStyles!.titleStyle,),
                              const SizedBox(height: 24),  // 增大间距
                              Container(
                                constraints: BoxConstraints(  // 响应式宽度
                                  maxWidth: constraints.maxWidth * 0.8,
                                  minWidth: 300
                                ),
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    hintText: "套题方案名称（必填）",
                                    border: OutlineInputBorder(),  // 添加边框
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: nameFieldCtrl,
                                  validator: (String? value) => value?.isEmpty ?? true ? "请输入有效的套题方案名称" : null,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.8,
                                  minWidth: 300
                                ),
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    hintText: "简介",
                                    border: OutlineInputBorder(),  // 统一输入框样式
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: descFieldCtrl,
                                  maxLines: 3,  // 允许多行输入
                                  minLines: 2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildRecoveryToggle(constraints),  // 提取复用组件
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: Text("创建", style: commonStyles!.titleStyle,),
                    content: Center(
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
                            child: Text('创建中，请稍候', style: commonStyles!.hintTextStyle,),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
        ),
      ),
    );
  }

  // 新增复用组件方法
  Widget _buildRecoveryToggle(BoxConstraints constraints) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      constraints: BoxConstraints(  // 新增宽度约束
        maxWidth: constraints.maxWidth * 0.8,
        minWidth: 300
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // 新增垂直居中
        children: [
          Padding(  // 新增文本内边距
            padding: const EdgeInsets.only(left: 16), 
            child: Text("是否为康复方案：", style: commonStyles?.bodyStyle),
          ),
          Padding(  // 新增开关内边距
            padding: const EdgeInsets.only(right: 8),
            child: Switch(
              value: isRecovery,
              onChanged: (bool value) => setState(() => isRecovery = value),
              activeColor: commonStyles?.primaryColor,
            )
          )
        ],
      ),
    );
  }
}


/// 套题编辑页面
class DoctorExamEditPage extends StatefulWidget {
  const DoctorExamEditPage({super.key});

  @override
  State<DoctorExamEditPage> createState() => _DoctorExamEditPageState();
}

class _DoctorExamEditPageState extends State<DoctorExamEditPage> with UseCommonStyles {
  double _menuWidth = 240.0;
  // final double _menuItemHeight = 50;
  double listTileCommonHeight = 32;
  double listTilePaddingBase = 8.0;
  late double tileLeadingWidth;
  late double tileContentWidth;

  dynamic editItem;
  int? editCategoryIndex;
  int? editSubCategoryIndex;
  int? editQuestionIndex;
  bool editingItem = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    tileLeadingWidth = 7 * listTilePaddingBase + 100;// 100是为expand按钮预留的宽度
    tileContentWidth = max(_menuWidth - tileLeadingWidth, 0);

    var examState = context.watch<ExamState>(); // 用于监听下层widget对Exam的修改

    commonStyles = initStyles(context);
    final paddingWidth = commonStyles?.commonPaddingWidth ?? 16.0;

    return Scaffold(
      appBar: AppBar(title: Text("编辑套题方案", style: commonStyles?.titleStyle,),),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(paddingWidth),
          child: LayoutBuilder(
              builder: (context, constraints) {
                return wrappedByCard (
                  elevation: 8.0,
                  child: Row(
                    children: [
                      GestureDetector(
                        onHorizontalDragUpdate: (detail) {
                          setState(() {
                            _menuWidth = max(tileLeadingWidth, min(600, _menuWidth + detail.primaryDelta!));
                          });
                        },
                        child: SizedBox(
                          width: _menuWidth,
                          height: constraints.maxHeight,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text("菜单", style: commonStyles?.titleStyle,),
                                const Divider(),
                                _buildSettingTile(examState),
                                const Divider(),
                                _buildQuestionTile(examState),
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: _buildActionArea(),
                      )
                    ],
                  ),
                );
              }
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(ExamState examState) {
    return ListTile(
      title: buildListTileContentWithActionButtons(
        body: Text("通用设置", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
        textAreaMaxHeight: listTileCommonHeight,
        textAreaMaxWidth: tileContentWidth + 60,
        commonStyles: commonStyles,
        firstBtnAction: () {
          continueAction() {
            setState(() {
              editItem = examState.exam;
            });
          }

          if (editingItem) {
            confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开通用设置？",
              commonStyles: commonStyles,
              onConfirm: (context) {
                continueAction();
                Navigator.pop(context);
              }
            );
          } else {
            continueAction();
          }
        },
        firstBtnIcon: editItem.runtimeType == ExamQuestionSet ? const Icon(Icons.edit_document): const Icon(Icons.edit),
        firstBtnTooltipMsg: "编辑"
      ),
      contentPadding: const EdgeInsets.only(left: 44),
    );
  }

  bool questionTileExpanded = false;

  Widget _buildQuestionTile(ExamState examState) {
    var editingExam = examState.exam;
    var categoryWidgets = <Widget>[];
    for (int i = 0;i < editingExam.categories.length;i++) {
      var category = editingExam.categories[i];
      var subCategoryWidgets = <Widget>[];
      for (int j = 0;j < category.subCategories.length;j++) {
        var subCategory = category.subCategories[j];
        var questionWidgets = <Widget>[];
        for (int k = 0;k < subCategory.questions.length;k++) {
          var question = subCategory.questions[k];
          questionWidgets.add(ListTile(
            contentPadding: EdgeInsets.only(left: 10 * listTilePaddingBase),
            title: buildListTileContentWithActionButtons(
              body: Text(question.alias ?? question.defaultQuestionName(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
              firstBtnAction: () {
                continueAction() {

                  Navigator.push<Question>(context, MaterialPageRoute(builder: (context) => DoctorExamQuestionEditPage(question: question,))).then((updated) {
                    setState(() {
                      if (updated != null) {
                        editingExam.updateQuestion(updated, categoryIndex: i,
                            subCategoryIndex: j,
                            questionIndex: k).then((value) {

                          setState(() {
                            editItem = editingExam.categories[i].subCategories[j];
                            editCategoryIndex = i;
                            editSubCategoryIndex = j;
                          });
                        }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});

                      }
                    });
                  });
                }
                if (editingItem) {
                  confirm(context,
                    title: "确认",
                    body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开题目编辑页面？",
                    commonStyles: commonStyles,
                    onConfirm: (context) {
                      Navigator.pop(context);
                      continueAction();
                    }
                  );
                } else {
                  continueAction();
                }
              },
              firstBtnTooltipMsg: "查看（编辑）题目详情",
              firstBtnIcon: const Icon(Icons.edit),
              secondBtnAction: () {
                confirm(context,
                    title: '删除问题',
                    body: '确认要删除问题："${question.alias ?? question.defaultQuestionName()}" 吗，删除后不可恢复',
                    commonStyles: commonStyles,
                    onConfirm: (context) {
                      // 关闭dialog
                      Navigator.pop(context);
                      examState.deleteQuestion(categoryIndex: i, subCategoryIndex: j, questionIndex: k)
                          .catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                    }
                );
              },
              secondBtnTooltipMsg: "删除",
              secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
              textAreaMaxHeight: listTileCommonHeight,
              textAreaMaxWidth: tileContentWidth,
              commonStyles: commonStyles
            ),
          ));
        }

        // 加入新增按钮
        questionWidgets.insert(0, Align(
          alignment: Alignment.center,
          child: _buildNewItemButton("新增题目", onPressed: () {
            commonAction() {
              Navigator.push<Question?>(context, MaterialPageRoute(builder: (context) => const DoctorExamQuestionEditPage())).then((newQuestion) {
                if (newQuestion != null) {
                  // debugPrint(jsonEncode(newQuestion.toJson()));
                  editingExam.addQuestion(newQuestion, categoryIndex: i, subCategoryIndex: j).then((addedQuestion) {
                    // debugPrint(jsonEncode(addedQuestion.toJson()));
                    setState(() {
                      editItem = editingExam.categories[i].subCategories[j];
                      editCategoryIndex = i;
                      editSubCategoryIndex = j;
                    });
                  }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                }
              });
            }
            if (editingItem) {
              confirm(context,
                  title: "确认",
                  body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开新增题目页面？",
                  commonStyles: commonStyles,
                  onConfirm: (context) {
                    Navigator.pop(context);
                    commonAction();
                  }
              );
            } else {
              commonAction();
            }
          }),
        ));

        bool editCurrentTile = editCategoryIndex == i && editSubCategoryIndex == j && editItem.runtimeType == QuestionSubCategory;
        subCategoryWidgets.add(ExpansionTile(
          backgroundColor: commonStyles!.theme.focusColor.withAlpha(40),
          tilePadding: EdgeInsets.only(left: 7 * listTilePaddingBase),
          controlAffinity: ListTileControlAffinity.leading,
          title: buildListTileContentWithActionButtons(
            body: Text(subCategory.description, style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
            textAreaMaxHeight: listTileCommonHeight,
            textAreaMaxWidth: tileContentWidth,
            commonStyles: commonStyles,
            firstBtnIcon: editCurrentTile ? Icon(Icons.edit_document, color: commonStyles?.primaryColor,) : const Icon(Icons.edit),
            firstBtnTooltipMsg: editCurrentTile ? "编辑中" : "编辑",
            firstBtnAction: editCurrentTile ? null : () {
              continueAction() {
                setState(() {
                  editItem = subCategory;
                  editCategoryIndex = i;
                  editSubCategoryIndex = j;
                });
              }

              if (editingItem) {
                confirm(context,
                    title: "确认",
                    body: '当前有未保存的编辑内容，是否丢弃这些内容并继续打开子项编辑页面？',
                    commonStyles: commonStyles,
                    onConfirm: (context) {
                      continueAction();
                      // 关闭dialog
                      Navigator.pop(context);
                    }
                );
              } else {
                continueAction();
              }
            },
            secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
            secondBtnTooltipMsg: "删除",
            secondBtnAction: () {
              confirm(context,
                  title: "删除子项",
                  body: '确认要删除子项："${subCategory.description}" 吗，删除后不可恢复。',
                  commonStyles: commonStyles,
                  onConfirm: (context) {
                    examState.deleteSubCategory(categoryIndex: i, subCategoryIndex: j).then((_) {
                      Navigator.pop(context);
                      setState(() {
                        if (editItem.runtimeType == QuestionSubCategory) {
                          assert(editSubCategoryIndex != null);
                          if (editSubCategoryIndex == j) {
                            editItem = null;
                            editCategoryIndex = null;
                            editSubCategoryIndex = null;
                            editingItem = false;
                          } else if (editSubCategoryIndex! > i) {
                            editSubCategoryIndex = editSubCategoryIndex! - 1;
                          }
                        }
                      });
                    }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                  }
              );
            }
          ),
          children: questionWidgets,
        ));
      }

      subCategoryWidgets.insert(0, Align(
        alignment: Alignment.center,
        child: _buildNewItemButton("新增子项", onPressed: () {
          if (editingItem) {
            confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开子项新增页？",
              commonStyles: commonStyles,
              onConfirm: (context) {
                editingExam.addSubCategory(categoryIndex: i).then((subCate) {
                  setState(() {
                    editItem = subCate;
                    editCategoryIndex = i;
                    editSubCategoryIndex = editingExam.categories[i].subCategories.length - 1;
                  });
                  // 关闭dialog
                  Navigator.pop(context);
                }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
              }
            );
          } else {
            editingExam.addSubCategory(categoryIndex: i).then((subCate) {
              setState(() {
                editItem = subCate;
                editCategoryIndex = i;
                editSubCategoryIndex = editingExam.categories[i].subCategories.length - 1;
              });
            }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
          }
        }),
      ));

      categoryWidgets.add(Builder(
        builder: (context) {
          bool notEditCurrentTile = editCategoryIndex != i || editItem.runtimeType != QuestionCategory;

          return ExpansionTile(
            backgroundColor: commonStyles?.theme.focusColor,
            key: Key("category$i"),
            tilePadding: EdgeInsets.only(left: 4 * listTilePaddingBase),
            controlAffinity: ListTileControlAffinity.leading,
            title: buildListTileContentWithActionButtons(
                body: Text(category.description, style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis),
                textAreaMaxHeight: listTileCommonHeight,
                textAreaMaxWidth: tileContentWidth,
                commonStyles: commonStyles,
                firstBtnIcon: notEditCurrentTile ? const Icon(Icons.edit) : Icon(Icons.edit_document, color: commonStyles?.primaryColor,),
                firstBtnTooltipMsg: notEditCurrentTile ? "编辑" : "编辑中",
                firstBtnAction: notEditCurrentTile ? () {
                  continueAction() {
                    setState(() {
                      // debugPrint("${editingExam.toJson()}\n${context.read<ExamState>().exam.toJson()}");
                      editItem = category;
                      editCategoryIndex = i;
                    });
                  }
                  if (editingItem) {
                    confirm(context,
                        title: "确认",
                        body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开亚项编辑页面？",
                        commonStyles: commonStyles,
                        onConfirm: (context) {
                          continueAction();
                          // 关闭dialog
                          Navigator.pop(context);
                        }
                    );
                  } else {
                    continueAction();
                  }
                } : null,
                secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,),
                secondBtnTooltipMsg: "删除",
                secondBtnAction: () {
                  confirm(context,
                      title: '删除亚项',
                      body: '确认要删除亚项："${category.description}" 吗，删除后不可恢复',
                      commonStyles: commonStyles,
                      onConfirm: (context) {
                        examState.deleteCategory(categoryIndex: i).then((_) {
                          setState(() {
                            if (editItem.runtimeType == QuestionCategory) {
                              assert(editCategoryIndex != null);
                              if (editCategoryIndex == i) {
                                editItem = null;
                                editCategoryIndex = null;
                                editingItem = false;
                              } else if (editCategoryIndex! > i) {
                                editCategoryIndex = editCategoryIndex! - 1;
                              }
                            }
                          });
                          // 关闭dialog
                          Navigator.pop(context);
                        }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                      }
                  );
                }
            ),
            children: [
              // _buildCategoryRuleTile(),
              ...subCategoryWidgets,
            ],
          );
        }
      )
      );
    }

    categoryWidgets.insert(0, Align(
      alignment: Alignment.center,
      child: _buildNewItemButton("新增亚项", onPressed: () {
        if (editingItem) {
          confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开新增亚项页面？",
              commonStyles: commonStyles,
              onConfirm: (context) {
                editingExam.addCategory().then((category) {
                  setState(() {
                    editItem = category;
                    editCategoryIndex = editingExam.categories.length - 1;
                  });
                  // 关闭dialog
                  Navigator.pop(context);
                }).catchError((err) {requestResultErrorHandler(context, error: err); return err;});
              }
          );
        } else {
          editingExam.addCategory().then((category) {
            setState(() {
              editItem = category;
              editCategoryIndex = editingExam.categories.length - 1;
            });
          }).catchError((err) {requestResultErrorHandler(context, error: err); return err;});
        }
      }),
    ));

    categoryWidgets = categoryWidgets.isEmpty ? [Text("无", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)] : categoryWidgets;

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: listTilePaddingBase),
      initiallyExpanded: true,
      title: buildListTileContentWithActionButtons(
        body: Text("套题目录", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
        textAreaMaxHeight: listTileCommonHeight,
        textAreaMaxWidth: tileContentWidth + 60,
        commonStyles: commonStyles,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      children: categoryWidgets.isEmpty ?
        [Text("无", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)] : categoryWidgets,
    );
  }

  Widget _buildItemName({required Widget child}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: listTileCommonHeight,
        maxWidth: tileContentWidth,
      ),
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }

  TextButton _buildNewItemButton(String text, {required void Function() onPressed}) {
    return TextButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add),
            Text(text, style: commonStyles?.bodyStyle,
              overflow: TextOverflow.ellipsis,),
          ],
        )
    );
  }

  Widget _buildActionArea() {
    Widget child;

    if (editItem == null) {
      child = const SizedBox.shrink();
    } else if (editItem.runtimeType == ExamQuestionSet) {
      child = ExamSettingEditSubPage(editItem, parentState: this,);
    } else if (editItem.runtimeType == QuestionCategory) {
      assert(editCategoryIndex != null);
      child = QuestionCategoryEditSubPage(editItem, categoryIndex: editCategoryIndex!, parentState: this,);
    } else if (editItem.runtimeType == QuestionSubCategory) {
      child = QuestionSubCategoryEditSubPage(editItem, categoryIndex: editCategoryIndex!, parentState: this, subCategoryIndex: editSubCategoryIndex!);
    } else {
      throw UnimplementedError("unexpected editItem");
    }

    return SizedBox.expand(
      child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.blueGrey),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 16.0,
              child: child,
            ),
          )
      ),
    );
  }
}

class ExamSettingEditSubPage extends StatefulWidget {
  final ExamQuestionSet exam;
  final _DoctorExamEditPageState _parentState;
  const ExamSettingEditSubPage(this.exam, {super.key, required State parentState})
    : _parentState = parentState as _DoctorExamEditPageState;

  @override
  State<ExamSettingEditSubPage> createState() => _ExamSettingEditSubPageState();
}

class _ExamSettingEditSubPageState extends State<ExamSettingEditSubPage> with UseCommonStyles {
  late ExamQuestionSet exam;

  TextEditingController examNameCtrl = TextEditingController(text: "");
  TextEditingController examDescCtrl = TextEditingController(text: "");
  var examNameValidator = (String? value) {
    if (value == null || value == "") {
      return "套题名称不可为空";
    } else if (value.length > 50) {
      return "请将套题名称控制在1-50个字符的长度范围内";
    } else {
      return null;
    }
  };
  var examDescValidator = (String? value) {
    if (value == null || value == "") {
      return "套题描述不可为空";
    } else if (value.length > 200) {
      return "请将套题描述控制在1-200个字符的长度范围内";
    } else {
      return null;
    }
  };

  GlobalKey<FormState> examNameFormKey = GlobalKey<FormState>(debugLabel: "examName");
  GlobalKey<FormState> examDescFormKey = GlobalKey<FormState>(debugLabel: "examDesc");

  bool editingName = false;
  bool editingDesc = false;

  double listTileCommonHeight = 32;

  @override
  void initState() {
    resetState();
    super.initState();
  }

  void resetState() {
    quitNameEdit();
    quitDescEdit();

    exam = widget.exam;
    examDescCtrl.text = exam.description;
    examNameCtrl.text = exam.name;
  }

  void _trySetNotEditing() {
    if (!editingName && !editingDesc) {
      widget._parentState.editingItem = false;
    }
  }

  void enterNameEdit() {
    editingName = true;
    widget._parentState.editingItem = true;
  }

  void quitNameEdit() {
    editingName = false;
    _trySetNotEditing();
  }

  void enterDescEdit() {
    editingDesc = true;
    widget._parentState.editingItem = true;
  }

  void quitDescEdit() {
    editingDesc = false;
    _trySetNotEditing();
  }

  void _showDiagnosisRuleSettingDialog({
    required BuildContext context,
    required ExamState examState,
    int? ruleIndex
  }) {
    showDialog(context: context, builder: (context) => ExamDiagnosisRuleEditDialog(examState: examState, ruleIndex: ruleIndex,));
  }

  @override
  Widget build(BuildContext context) {
    if (exam != widget.exam) {
      resetState();
    }

    commonStyles = initStyles(context);
    ExamState examState = context.watch<ExamState>();
    assert(examState.exam == exam);

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
                            // 标题
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("套题设置：",
                                  style: commonStyles?.titleStyle,
                                ),
                              ),
                            ),
                            // 中间的通用设置
                            Expanded(
                              flex: 4,
                              child: Column (
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // 套题名称和描述
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              Widget textOrForm;
                                              int btnState;
                                              if (editingName) {
                                                textOrForm = Form(
                                                    key: examNameFormKey,
                                                    child: Container(
                                                      constraints: const BoxConstraints(maxWidth: 200, minWidth: 20),
                                                      child: TextFormField(
                                                        controller: examNameCtrl,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        validator: examNameValidator,
                                                      ),
                                                    )
                                                );
                                                btnState = 1;
                                              } else {
                                                textOrForm = Text(exam.name, style: commonStyles?.bodyStyle,);
                                                btnState = 0;
                                              }

                                              return Row(
                                                children: [
                                                  Text("套题名称：", style: commonStyles?.bodyStyle),
                                                  Expanded(child: textOrForm),
                                                  CircleIconSwitchTextButton(
                                                    btnSetting: [
                                                      CircleIconSwitchTextButton.btnSettingWith(
                                                        btnIcon: const Icon(Icons.edit),
                                                        btnAction: () {
                                                          setState(() {
                                                            enterNameEdit();
                                                          });
                                                        },
                                                        btnTooltipMsg: "编辑"
                                                      ),
                                                      CircleIconSwitchTextButton.btnSettingWith(
                                                          btnIcon: const Icon(Icons.check),
                                                          btnAction: () {
                                                            if (examNameFormKey.currentState!.validate()) {
                                                              if (examNameCtrl.text == exam.name) {
                                                                setState(() {
                                                                  quitNameEdit();
                                                                });
                                                                return;
                                                              }

                                                              examState.updateName(newName: examNameCtrl.text).then((_) {
                                                                setState(() {
                                                                  quitNameEdit();
                                                                });
                                                              }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                            }
                                                          },
                                                          btnTooltipMsg: "完成"
                                                      ),
                                                    ],
                                                    state: btnState
                                                  )
                                                ],
                                              );
                                            }
                                          ),
                                        ),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              Widget textOrForm;
                                              int btnState;
                                              if (editingDesc) {
                                                textOrForm = Form(
                                                    key: examDescFormKey,
                                                    child: Container(
                                                      constraints: const BoxConstraints(maxWidth: 200, minWidth: 20),
                                                      child: TextFormField(
                                                        controller: examDescCtrl,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        validator: examDescValidator,
                                                      ),
                                                    )
                                                );
                                                btnState = 1;
                                              } else {
                                                textOrForm = Text(exam.description, style: commonStyles?.bodyStyle,);
                                                btnState = 0;
                                              }

                                              return Row(
                                                children: [
                                                  Text("套题描述：", style: commonStyles?.bodyStyle),
                                                  Expanded(child: textOrForm),
                                                  CircleIconSwitchTextButton(
                                                    btnSetting: [
                                                      CircleIconSwitchTextButton.btnSettingWith(
                                                          btnIcon: const Icon(Icons.edit),
                                                          btnAction: () {
                                                            setState(() {
                                                              enterDescEdit();
                                                            });
                                                          },
                                                          btnTooltipMsg: "编辑"
                                                      ),
                                                      CircleIconSwitchTextButton.btnSettingWith(
                                                          btnIcon: const Icon(Icons.check),
                                                          btnAction: () {
                                                            if (examDescFormKey.currentState!.validate()) {
                                                              if (examDescCtrl.text == exam.description) {
                                                                setState(() {
                                                                  quitDescEdit();
                                                                });
                                                                return;
                                                              }
                                                              examState.updateDescription(newDescription: examDescCtrl.text).then((_) {
                                                                setState(() {
                                                                  quitDescEdit();
                                                                });
                                                              }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                            }
                                                          },
                                                          btnTooltipMsg: "完成"
                                                      ),
                                                    ],
                                                    state: btnState
                                                  )
                                                ],
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 套题发布状态
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text("发布状态：", style: commonStyles?.bodyStyle),
                                              Text(exam.published ? "已发布" : "未发布", style: commonStyles?.bodyStyle),
                                              const SizedBox(width: 16,),
                                              exam.published ? const SizedBox.shrink()
                                                  :
                                              ElevatedButton (
                                                onPressed: () {
                                                  showDialog(context: context, builder: (context) => AlertDialog(
                                                    title: Text("发布套题", style: commonStyles?.titleStyle),
                                                    content: Text("确定要发布套题吗？发布后不可取消发布，且无法再修改套题内容。", style: commonStyles?.bodyStyle),
                                                    actions: [
                                                      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("取消", style: commonStyles?.bodyStyle)),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          examState.publish()
                                                              .then((_) => Navigator.pop(context))
                                                              .catchError((err) {
                                                                requestResultErrorHandler(context, error: err);
                                                                return err;
                                                              });
                                                          },
                                                        style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
                                                        child: Text("确认", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor)),)
                                                    ],
                                                  ));
                                                },
                                                child: Text("发布套题", style: commonStyles?.bodyStyle)
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text("套题类型：${exam.recovery ?"康复方案": "测评量表"}", style: commonStyles?.bodyStyle,),
                                            ],
                                          )
                                        ),
                                      ],
                                    )
                                  )
                                ],
                              )
                            ),
                            Expanded(
                              flex: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey)
                                      ),
                                      child: Column(
                                        children: [
                                          Text("诊断规则列表", style: commonStyles?.bodyStyle,),
                                          const Divider(),
                                          Expanded(
                                              child: LayoutBuilder(
                                                  builder: (BuildContext context, BoxConstraints constraints) {
                                                    return ListView.builder(
                                                      controller: verticalScrollCtrl,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        var rule = examState.exam.diagnosisRules[index] as DiagnoseByScoreRange;
                                                        return ListTile(
                                                          key: Key(index.toString()),
                                                          title: buildListTileContentWithActionButtons(
                                                              body: Text("${index+1}. ${rule.aphasiaType}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                              firstBtnAction: () {
                                                                _showDiagnosisRuleSettingDialog(
                                                                  context: context,
                                                                  examState: examState,
                                                                  ruleIndex: index
                                                                );
                                                              },
                                                              firstBtnTooltipMsg: "编辑",
                                                              firstBtnIcon: const Icon(Icons.edit),
                                                              secondBtnAction: () {
                                                                confirm(context,
                                                                  title: "删除诊断规则",
                                                                  body: "确认要删除诊断规则：${rule.aphasiaType} 吗？",
                                                                  commonStyles: commonStyles,
                                                                  onConfirm: (context) {
                                                                    examState.deleteDiagnosisRule(ruleIndex: index)
                                                                        .then((value) {
                                                                          // 关闭dialog
                                                                          Navigator.pop(context);
                                                                        }).catchError((err) {requestResultErrorHandler(context, error: err); return err;});
                                                                  }
                                                                );
                                                              },
                                                              secondBtnTooltipMsg: "删除",
                                                              secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles!.errorColor,),
                                                              textAreaMaxHeight: listTileCommonHeight,
                                                              textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                              commonStyles: commonStyles),
                                                        );
                                                      },
                                                      itemCount: examState.exam.diagnosisRules.length,
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
                                                    _showDiagnosisRuleSettingDialog(
                                                      context: context,
                                                      examState: examState,
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
                                    ),
                                  ),
                                  const SizedBox(width: 16,),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey)
                                      ),
                                      child: Column(
                                        children: [
                                          Text("亚项列表", style: commonStyles?.bodyStyle,),
                                          const Divider(),
                                          Expanded(
                                              child: LayoutBuilder(
                                                  builder: (BuildContext context, BoxConstraints constraints) {
                                                    return ListView.builder(
                                                      controller: verticalScrollCtrl,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        var category = examState.exam.categories[index];
                                                        return ListTile(
                                                          key: Key(index.toString()),
                                                          title: buildListTileContentWithActionButtons(
                                                              body: Text("${index+1}. ${category.description}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                                              firstBtnAction: () {
                                                                if (index > 0) {
                                                                  examState.moveCategoryUp(categoryIndex: index,).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                                }
                                                              },
                                                              firstBtnTooltipMsg: "上移",
                                                              firstBtnIcon: const Icon(Icons.arrow_upward),
                                                              secondBtnAction: () {
                                                                if (index < examState.exam.categories.length - 1) {
                                                                  examState.moveCategoryDown(categoryIndex: index,).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                                }
                                                              },
                                                              secondBtnTooltipMsg: "下移",
                                                              secondBtnIcon: const Icon(Icons.arrow_downward),
                                                              textAreaMaxHeight: listTileCommonHeight,
                                                              textAreaMaxWidth: max(constraints.maxWidth - 100, 0),
                                                              commonStyles: commonStyles),
                                                        );
                                                      },
                                                      itemCount: examState.exam.categories.length,
                                                    );
                                                  }
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
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

class QuestionCategoryEditSubPage extends StatefulWidget {
  final QuestionCategory category;
  final int categoryIndex;
  final _DoctorExamEditPageState _parentState;

  QuestionCategoryEditSubPage(this.category, {super.key, required this.categoryIndex, required State parentState})
    : assert(parentState.runtimeType == _DoctorExamEditPageState),
        _parentState = parentState as _DoctorExamEditPageState;

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
    widget._parentState.editingItem = true;
    descController.text = currCategory.description;
  }

  void _disableDescInput () {
    editingDesc = false;
    widget._parentState.editingItem = false;
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

class QuestionSubCategoryEditSubPage extends StatefulWidget {
  final QuestionSubCategory subCategory;
  final int categoryIndex;
  final int subCategoryIndex;
  final _DoctorExamEditPageState _parentState;

  QuestionSubCategoryEditSubPage(this.subCategory, {super.key, required this.categoryIndex, required this.subCategoryIndex, required State parentState})
    : assert(parentState.runtimeType == _DoctorExamEditPageState),
      _parentState = parentState as _DoctorExamEditPageState;


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

