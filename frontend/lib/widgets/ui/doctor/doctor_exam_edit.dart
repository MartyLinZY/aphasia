import 'dart:async';
import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/category.dart';
import '../../../models/exam/sub_category.dart';
import '../../../utils/common_widget_function.dart';
import 'doctor_exam_edit_dialogs.dart';
import 'doctor_exam_question_edit.dart';
import 'doctor_exam_setting_edit_sub_page.dart';
import 'doctor_question_category_edit_sub_page.dart';
import 'doctor_question_sub_category_edit_sub_page.dart';


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
  State<DoctorExamEditPage> createState() => DoctorExamEditPageState();
}

class DoctorExamEditPageState extends State<DoctorExamEditPage> with UseCommonStyles {
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
