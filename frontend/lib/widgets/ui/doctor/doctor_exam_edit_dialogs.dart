import 'package:aphasia_recovery/models/rules.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../states/question_set_states.dart';
import '../../../utils/common_widget_function.dart';

class ExamDiagnosisRuleEditDialog extends StatefulWidget {
  final ExamState examState;
  final int? ruleIndex;
  const ExamDiagnosisRuleEditDialog(
      {super.key, required this.examState, this.ruleIndex});

  @override
  State<ExamDiagnosisRuleEditDialog> createState() =>
      _ExamDiagnosisRuleEditDialogState();
}

class _ExamDiagnosisRuleEditDialogState
    extends State<ExamDiagnosisRuleEditDialog> with UseCommonStyles {
  DiagnoseByScoreRange? oldRule;
  late DiagnoseByScoreRange rule;
  late List<bool> categoriesSelected;
  final GlobalKey<FormState> _formKey =
      GlobalKey(debugLabel: "DiagnosisRuleEdit");

  bool editingAphasiaType = false;
  TextEditingController aphasiaTypeCtrl = TextEditingController();

  List<List<TextEditingController>> scoreRangeControllers = [];

  // 新增空安全校验
  bool get _isValidCategoryIndex =>
      widget.ruleIndex == null ||
      (widget.ruleIndex! < widget.examState.exam.diagnosisRules.length);

  void resetState() {
    if (!_isValidCategoryIndex) return;
    quitEditAphasiaType();

    rule = DiagnoseByScoreRange(aphasiaType: "失语症类型");
    if (widget.ruleIndex != null) {
      oldRule = widget.examState.exam.diagnosisRules[widget.ruleIndex!]
          as DiagnoseByScoreRange;
      rule = oldRule!.copy();
    }

    var currRule = rule;

    aphasiaTypeCtrl.text = currRule.aphasiaType;

    categoriesSelected = [];
    for (var i = 0; i < widget.examState.exam.categories.length; i++) {
      categoriesSelected.add(false);
    }

    scoreRangeControllers = [];
    for (var i = 0; i < rule.categoryIndices.length; i++) {
      categoriesSelected[rule.categoryIndices[i]] = true;
      scoreRangeControllers.add([
        TextEditingController(text: currRule.ranges[i].min.toString()),
        TextEditingController(text: currRule.ranges[i].max.toString())
      ]);
    }
  }

  void quitEditAphasiaType() {
    editingAphasiaType = false;
  }

  void enterEditAphasiaType() {
    editingAphasiaType = true;
  }

  void selectCategory(int i) {
    // 添加范围检查
    if (i < 0 || i >= widget.examState.exam.categories.length) return;

    setState(() {
      categoriesSelected[i] = true;
      rule.categoryIndices.add(i);
      rule.ranges.add(ScoreRange(min: 0, max: 10));
      scoreRangeControllers.add([
        TextEditingController(text: "0"),
        TextEditingController(text: "10")
      ]);
    });
  }

  void deselectCategory(int i) {
    categoriesSelected[i] = false;

    var index = rule.categoryIndices.indexOf(i);
    if (index >= 0) {
      rule.categoryIndices.removeAt(index);
      rule.ranges.removeAt(index);
      scoreRangeControllers.removeAt(index);
    }
  }

  @override
  void initState() {
    if (!_isValidCategoryIndex) {
      Navigator.pop(context);
      return;
    }
    resetState();
    super.initState();
  }

  String? aphasiaTypeValidator(String? value) {
    if (value == null || value == "") {
      return "诊断不可为空";
    } else {
      return null;
    }
  }

  String? scoreRangeValidator(String? value) {
    if (value == null || value == "") {
      return "范围取值不可为空";
    } else {
      double? num = double.tryParse(value);
      if (num == null) {
        return "请输入数字";
      } else if (num < 0) {
        return "请输入大于0的数字";
      } else {
        return null;
      }
    }
  }

  String? Function(String? value) minScoreValidator(int rangeIndex) {
    return (String? value) {
      String? errMsg = scoreRangeValidator(value);
      if (errMsg == null) {
        double max = rule.ranges[rangeIndex].max;
        double? min = double.tryParse(value!);
        if (min! > max) {
          errMsg = "下限值不可大于上限值";
        }
      }

      return errMsg;
    };
  }

  String? Function(String? value) maxScoreValidator(int rangeIndex) {
    return (String? value) {
      String? errMsg = scoreRangeValidator(value);
      if (errMsg == null) {
        double min = rule.ranges[rangeIndex].min;
        double? max = double.tryParse(value!);
        if (min > max!) {
          errMsg = "上限值不可小于下限值";
        }
      }

      return errMsg;
    };
  }

  Widget _buildCategoryCheckbox(int index) {
    final category = widget.examState.exam.categories[index];
    return Tooltip(
      message: category.description,
      child: FilterChip(
        label: Text(category.description,
            style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis),
        selected: categoriesSelected[index],
        onSelected: (selected) => setState(() {
          if (selected) {
            selectCategory(index);
          } else {
            deselectCategory(index);
          }
        }),
      ),
    );
  }

  Widget _buildScoreInput(int index, bool isMin) {
    return TextFormField(
      controller: scoreRangeControllers[index][isMin ? 0 : 1],
      decoration: InputDecoration(
          labelText: isMin ? '最小值' : '最大值', border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      validator: isMin ? minScoreValidator(index) : maxScoreValidator(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 添加错误处理
    if (!_isValidCategoryIndex) {
      return const SizedBox.shrink();
    }
    initStyles(context);

    var media = MediaQuery.of(context);
    var categoryCheckBoxCountPerLine = media.size.width > 1200 ? 5 : 3;

    var examState = widget.examState;
    var ruleIndex = widget.ruleIndex;
    if (ruleIndex != null &&
        oldRule != examState.exam.diagnosisRules[ruleIndex]) {
      resetState();
    }

    var currRule = rule;

    return buildSimpleActionDialog(
      context,
      title: "编辑诊断规则",
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                widget.examState.exam.categories.length,
                (index) => _buildCategoryCheckbox(index)
              ),
            ),
            const SizedBox(height: 32),
            // Text("选择诊断所涉及的亚项：", style: commonStyles?.bodyStyle,),
            // GridView.count(
            //   shrinkWrap: true,
            //   crossAxisCount: categoryCheckBoxCountPerLine,
            //   childAspectRatio: (4 / 1),
            //   children: examState.exam.categories.asMap().entries.map((e) {
            //     double maxScore = 0;
            //     for (var subCate in e.value.subCategories) {
            //       for (var element in subCate.questions) {
            //         maxScore += (element.evalRule?.fullScore ?? 0);
            //       }
            //     }

                // return Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     Checkbox(
                //       value: categoriesSelected[e.key],
                //       onChanged: (bool? value) {
                //         setState(() {
                //           if (value == null || !value) {
                //             deselectCategory(e.key);
                //           } else {
                //             selectCategory(e.key);
                //           }
                //         });
                //       }
                //     ),
            //         Tooltip(
            //           message: '${examState.exam.categories[e.key].description}（满分$maxScore）',
            //           child: Container(
            //             constraints: BoxConstraints(maxWidth: media.size.width > 800? 100.0 : 72.0),
            //             child: OverflowBox(
            //               alignment: AlignmentDirectional.centerStart,
            //               child: Text(examState.exam.categories[e.key].description, style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)
            //             ),
            //           ),
            //         ),
            //       ],
            //     );
            //   }).toList(),
            // ),
            // const Divider(height: 32,),
            // Text("设置生效条件：", style: commonStyles?.bodyStyle,),
            Table(
              // border: TableBorder.all(),
              // columnWidths: const<int, TableColumnWidth> {
              //   0: FlexColumnWidth(),
              //   1: FlexColumnWidth(),
              //   2: FlexColumnWidth(),
              // },
              children: [
                // TableRow(
                //   children: [
                //     Center(child: Text("亚项名称", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                //     Center(child: Text("分数下界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                //     Center(child: Text("分数上界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,))
                //   ]
                // ),
                TableRow(
                  children: ['亚项', '分数范围'].map((text) => 
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(text, 
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center),
                    )).toList()
                ),
                ...rule.categoryIndices.asMap().entries.map((e) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),  // 增加垂直内边距
                      child: Text(widget.examState.exam.categories[e.value].description),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),  // 添加容器内边距
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4), 
                              child: _buildScoreInput(e.key, true),
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("~")),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),  // 输入框上下间距
                              child: _buildScoreInput(e.key, false),
                            ),
                          ),
                        ],
                      )
                    )
                  ]
                )),
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Container(
                      height: 16, // 设置行间距高度
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.transparent)
                        )
                      ),
                    )
                  ]
                )
                // ...currRule.categoryIndices.asMap().entries.map((e) => TableRow(
                //     children: [
                //       Center(child: Text(examState.exam.categories[currRule.categoryIndices[e.key]].description, style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                //       Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                //         child: TextFormField(
                //           autovalidateMode: AutovalidateMode.onUserInteraction,
                //           decoration: const InputDecoration(border: OutlineInputBorder()),
                //           controller: scoreRangeControllers[e.key][0],
                //           validator: minScoreValidator(e.key),
                //           onChanged: (String? value) {
                //             if (scoreRangeValidator(value) == null) {
                //               rule.ranges[e.key].min = double.tryParse(scoreRangeControllers[e.key][0].text)!;
                //             }
                //           },
                //         ),
                //       ),
                //       Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                //         child: TextFormField(
                //           autovalidateMode: AutovalidateMode.onUserInteraction,
                //           decoration: const InputDecoration(border: OutlineInputBorder()),
                //           controller: scoreRangeControllers[e.key][1],
                //           validator: maxScoreValidator(e.key),
                //             onChanged: (String? value) {
                //             if (scoreRangeValidator(value) == null) {
                //                 rule.ranges[e.key].max = double.tryParse(scoreRangeControllers[e.key][1].text)!;
                //               }
                //             }
                //         ),
                //       ),
                //     ]
                // )).toList(),
              ],
            ),
            const Divider(height: 32),  // 添加分隔线并设置高度
            const SizedBox(height: 24),  // 新增间距
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("诊断：", style: commonStyles?.bodyStyle, ),
                const SizedBox(width: 16),  // 增加水平间距
                Container(
                  constraints: const BoxConstraints(maxWidth: 300, minWidth: 100),
                  child: TextFormField(
                    maxLines: 2,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: aphasiaTypeCtrl,
                    validator: aphasiaTypeValidator,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()
                    ),
                    onChanged: (String? value) {
                      currRule.aphasiaType = value ?? "";
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),  // 底部增加间距
          ],
        ),
      ),
      commonStyles: commonStyles,
      onConfirm: (context) {
        if (!_formKey.currentState!.validate()) {
          return;
        }

        if (rule.ranges.isEmpty) {
          toast(context, msg: "请至少选中一个亚项并设置范围", btnText: "确认");
          return;
        }

        if (ruleIndex != null) {
          examState.updateDiagnosisRule(updatedRule: currRule, ruleIndex: ruleIndex)
              .then((_) => Navigator.pop(context))
              .catchError((err) {
            requestResultErrorHandler(context, error: err);
            return err;
          });
        } else {
          examState.addDiagnosisRule(newRule: currRule)
              .then((_) => Navigator.pop(context))
              .catchError((err) {
            requestResultErrorHandler(context, error: err);
            return err;
          });
        }
      },
    );
  }
}


class SubCategoryEvalRuleEditDialog extends StatefulWidget {
  final int categoryIndex;
  final int subCategoryIndex;
  final int? ruleIndex;
  final ExamState examState;

  const SubCategoryEvalRuleEditDialog(
      {super.key,
      required this.categoryIndex,
      required this.subCategoryIndex,
      this.ruleIndex,
      required this.examState});

  @override
  State<SubCategoryEvalRuleEditDialog> createState() =>
      _SubCategoryEvalRuleEditDialogState();
}

class _SubCategoryEvalRuleEditDialogState
    extends State<SubCategoryEvalRuleEditDialog> with UseCommonStyles {
  Type? selectedRuleType;
  late ExamSubCategoryEvalRule rule;

  @override
  void initState() {
    rule = EvalSubCategoryByQuestionScoreSum();
    selectedRuleType = rule.runtimeType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    int categoryIndex = widget.categoryIndex;
    int subCategoryIndex = widget.subCategoryIndex;
    int? ruleIndex = widget.ruleIndex;

    var examState = widget.examState;
    var subCategory = examState
        .exam.categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex != null) {
      rule = subCategory.evalRules[ruleIndex].copy();
      selectedRuleType = rule.runtimeType;
    }

    Widget ruleSettingArea;

    switch (rule.runtimeType) {
      case EvalSubCategoryByQuestionScoreSum:
        ruleSettingArea = Text(
          "该规则无可修改属性",
          style: commonStyles?.bodyStyle,
        );
        break;
      default:
        throw UnimplementedError();
    }

    return buildSimpleActionDialog(context,
        title: "子项评分规则：",
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "规则类型：",
                  style: commonStyles?.bodyStyle,
                ),
                DropdownMenu(
                  initialSelection: selectedRuleType,
                  requestFocusOnTap: false,
                  enableSearch: false,
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                        value: EvalSubCategoryByQuestionScoreSum,
                        label:
                            EvalSubCategoryByQuestionScoreSum().displayName())
                  ],
                  onSelected: (selected) {
                    setState(() {
                      if (selected != selectedRuleType) {
                        selectedRuleType = selected;
                        switch (selected) {
                          case EvalSubCategoryByQuestionScoreSum:
                            rule = EvalSubCategoryByQuestionScoreSum();
                            break;
                          default:
                            throw UnimplementedError();
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            ruleSettingArea
          ],
        ), onConfirm: (context) {
      if (ruleIndex == null) {
        examState
            .addSubCategoryEvalRule(
                categoryIndex: categoryIndex,
                newRule: rule,
                subCategoryIndex: subCategoryIndex)
            .then((_) {
          Navigator.pop(context);
        }).catchError((err) {
          requestResultErrorHandler(context, error: err);
          return err;
        });
      } else {
        examState
            .updateSubCategoryEvalRule(
                categoryIndex: categoryIndex,
                updatedEvalRule: rule,
                ruleIndex: ruleIndex,
                subCategoryIndex: subCategoryIndex)
            .then((_) {
          Navigator.pop(context);
        }).catchError((err) {
          requestResultErrorHandler(context, error: err);
          return err;
        });
      }
    }, commonStyles: commonStyles);
  }
}

class SubCategoryTerminateRuleEditDialog extends StatefulWidget {
  final int categoryIndex;
  final int subCategoryIndex;
  final int? ruleIndex;
  final ExamState examState;

  const SubCategoryTerminateRuleEditDialog(
      {super.key,
      required this.categoryIndex,
      required this.subCategoryIndex,
      this.ruleIndex,
      required this.examState});

  @override
  State<SubCategoryTerminateRuleEditDialog> createState() =>
      _SubCategoryTerminateRuleEditDialogState();
}

class _SubCategoryTerminateRuleEditDialogState
    extends State<SubCategoryTerminateRuleEditDialog> with UseCommonStyles {
  Type? selectedRuleType;
  late TerminateRule rule;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController continuousWrongRuleThresholdCtrl =
      TextEditingController(text: "");
  TextEditingController equivScoreCtrl = TextEditingController(text: "");
  TextEditingController terminateReasonCtrl = TextEditingController(text: "");

  @override
  void initState() {
    if (widget.ruleIndex == null) {
      rule = ContinuousWrongAnswerTerminate(
          reason: "连续答错", equivalentScore: 0, errorCountThreshold: 3);
    } else {
      rule = widget
          .examState
          .exam
          .categories[widget.categoryIndex]
          .subCategories[widget.subCategoryIndex]
          .terminateRules[widget.ruleIndex!];
    }
    selectedRuleType = rule.runtimeType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);
    double settingRowHeight = 80.0;

    int categoryIndex = widget.categoryIndex;
    int subCategoryIndex = widget.subCategoryIndex;
    int? ruleIndex = widget.ruleIndex;

    var examState = widget.examState;
    var subCategory = examState
        .exam.categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex != null) {
      rule = subCategory.terminateRules[ruleIndex].copy();
      selectedRuleType = rule.runtimeType;
    }

    terminateReasonCtrl.text = rule.reason;
    equivScoreCtrl.text = rule.equivalentScore.toString();

    List<Widget> ruleSpecificSetting = [];
    switch (rule.runtimeType) {
      case ContinuousWrongAnswerTerminate:
        assert(rule.runtimeType == ContinuousWrongAnswerTerminate);
        continuousWrongRuleThresholdCtrl.text =
            (rule as ContinuousWrongAnswerTerminate)
                .errorCountThreshold
                .toString();
        ruleSpecificSetting.add(SizedBox(
          height: settingRowHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "连续答错题数阈值：",
                style: commonStyles?.bodyStyle,
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 200),
                child: TextFormField(
                  controller: continuousWrongRuleThresholdCtrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (String? value) {
                    if (value == null || value == "") {
                      return "阈值不可为空";
                    } else if (int.tryParse(value) == null) {
                      return "请输入数字";
                    } else {
                      return null;
                    }
                  },
                  onChanged: (String? value) {
                    (rule as ContinuousWrongAnswerTerminate)
                        .errorCountThreshold = int.tryParse(value ?? "") ?? 0;
                  },
                ),
              )
            ],
          ),
        ));

        break;
      default:
        throw UnimplementedError();
    }

    Widget ruleSettingArea = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "终止原因：",
                  style: commonStyles?.bodyStyle,
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextFormField(
                    controller: terminateReasonCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (String? value) {
                      if (value == null || value == "") {
                        return "终止原因不可为空";
                      } else {
                        return null;
                      }
                    },
                    onChanged: (String? value) {
                      rule.reason = value ?? "";
                    },
                  ),
                )
              ],
            ),
          ),
          // SizedBox(
          //   height: 80,
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Text("终止后子项分数：", style: commonStyles?.bodyStyle,),
          //       Container(
          //         constraints: const BoxConstraints(maxWidth: 200),
          //         child: TextFormField(
          //           controller: equivScoreCtrl,
          //           autovalidateMode: AutovalidateMode.onUserInteraction,
          //           validator: (String? value) {
          //             if (value == null || value == "") {
          //               return "终止后分数不可为空";
          //             } else if (double.tryParse(value) == null) {
          //               return "请输入数字";
          //             } else {
          //               return null;
          //             }
          //           },
          //           onChanged: (String? value) {
          //             rule.equivalentScore = double.tryParse(value ?? "") ?? 0;
          //           },
          //         ),
          //       )
          //     ],
          //   ),
          // ),
          ...ruleSpecificSetting
        ],
      ),
    );

    return buildSimpleActionDialog(context,
        title: "子项终止规则：",
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "规则类型：",
                  style: commonStyles?.bodyStyle,
                ),
                DropdownMenu(
                  width: 300,
                  initialSelection: selectedRuleType,
                  requestFocusOnTap: false,
                  enableSearch: false,
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                        value: ContinuousWrongAnswerTerminate,
                        label: ContinuousWrongAnswerTerminate.ruleDisplayName())
                  ],
                  onSelected: (selected) {
                    setState(() {
                      if (selected != selectedRuleType) {
                        selectedRuleType = selected;
                        switch (selected) {
                          case EvalSubCategoryByQuestionScoreSum:
                            var threshold = 3;
                            rule = ContinuousWrongAnswerTerminate(
                                reason: "连续答错$threshold题",
                                equivalentScore: 0,
                                errorCountThreshold: threshold);
                            break;
                          default:
                            throw UnimplementedError();
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            ruleSettingArea
          ],
        ), onConfirm: (context) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (ruleIndex == null) {
        examState
            .addSubCategoryTerminateRule(
                categoryIndex: categoryIndex,
                newRule: rule,
                subCategoryIndex: subCategoryIndex)
            .then((_) {
          Navigator.pop(context);
        }).catchError((err) {
          requestResultErrorHandler(context, error: err);
          return err;
        });
      } else {
        examState
            .updateSubCategoryTerminateRule(
                categoryIndex: categoryIndex,
                updatedEvalRule: rule,
                ruleIndex: ruleIndex,
                subCategoryIndex: subCategoryIndex)
            .then((_) {
          Navigator.pop(context);
        }).catchError((err) {
          requestResultErrorHandler(context, error: err);
          return err;
        });
      }
    }, commonStyles: commonStyles);
  }
}
