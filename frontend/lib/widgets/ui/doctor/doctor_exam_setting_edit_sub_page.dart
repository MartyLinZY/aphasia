import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/widgets/ui/common/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/common_widget_function.dart';
import 'doctor_exam_edit_dialogs.dart';

class ExamSettingEditSubPage extends StatefulWidget {
  final ExamQuestionSet exam;
  const ExamSettingEditSubPage(this.exam, {super.key});

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

  /// 移动 category 上下的 HTTP 期间置 true，把所有 category 的"上/下"按钮 null 化
  /// （TextButton onPressed:null 自动灰）防双击触发重复 reorder。一次只允许一个
  /// 移动操作，所以所有 category 共享一个 flag。
  bool _moving = false;

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
      context.read<ExamEditSelectionState>().editingItem = false;
    }
  }

  void enterNameEdit() {
    editingName = true;
    context.read<ExamEditSelectionState>().editingItem = true;
  }

  void quitNameEdit() {
    editingName = false;
    _trySetNotEditing();
  }

  void enterDescEdit() {
    editingDesc = true;
    context.read<ExamEditSelectionState>().editingItem = true;
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
                                                              firstBtnAction: _moving
                                                                  ? null
                                                                  : () {
                                                                      if (index > 0) {
                                                                        setState(() => _moving = true);
                                                                        examState.moveCategoryUp(categoryIndex: index)
                                                                            .whenComplete(() {
                                                                              if (mounted) setState(() => _moving = false);
                                                                            })
                                                                            .catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                                                                      }
                                                                    },
                                                              firstBtnTooltipMsg: "上移",
                                                              firstBtnIcon: const Icon(Icons.arrow_upward),
                                                              secondBtnAction: _moving
                                                                  ? null
                                                                  : () {
                                                                      if (index < examState.exam.categories.length - 1) {
                                                                        setState(() => _moving = true);
                                                                        examState.moveCategoryDown(categoryIndex: index)
                                                                            .whenComplete(() {
                                                                              if (mounted) setState(() => _moving = false);
                                                                            })
                                                                            .catchError((err) { requestResultErrorHandler(context, error: err); return err;});
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
