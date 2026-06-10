import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';

class QuestionScoreConditionEditDialog extends StatefulWidget {
  final EvalCondition? condition;
  final QuestionEvalRule evalRule;
  final String scoreConditionName;
  const QuestionScoreConditionEditDialog(
      {super.key,
      this.condition,
      required this.scoreConditionName,
      required this.evalRule});

  @override
  State<QuestionScoreConditionEditDialog> createState() =>
      _QuestionScoreConditionEditDialogState();
}

class _QuestionScoreConditionEditDialogState
    extends State<QuestionScoreConditionEditDialog> with UseCommonStyles {
  late EvalCondition condition;
  late QuestionEvalRule currEvalRule;

  Map<String, Map<String, dynamic>> fieldsSetting = {};

  bool useTimeBound = false;
  bool isHinted = false;

  String? basicValidator(String? value) {
    if (value == null || value == "") {
      return "范围取值不可为空";
    } else {
      double? num = double.tryParse(value);
      if (num == null) {
        return "请输入数字";
      } else if (num < 0) {
        return "请输入大于等于0的数字";
      } else {
        return null;
      }
    }
  }

  String? scoreValidator(String? value) {
    return basicValidator(value);
  }

  String? mainLowBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num >
          (double.tryParse(fieldsSetting["mainHighBound"]!['ctrl'].text) ??
              double.infinity)) {
        errMsg = "下界不可大于上界";
      }
    }
    return errMsg;
  }

  String? mainHighBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num <
          (double.tryParse(fieldsSetting["mainLowBound"]!['ctrl'].text) ?? 0)) {
        errMsg = "上界不可小于下界";
      }
    }
    return errMsg;
  }

  String? timeLowBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num >
          (double.tryParse(fieldsSetting["timeHighBound"]!['ctrl'].text) ??
              double.infinity)) {
        errMsg = "下界不可大于上界";
      }
    }
    return errMsg;
  }

  String? timeHighBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num <
          (double.tryParse(fieldsSetting["timeLowBound"]!['ctrl'].text) ?? 0)) {
        errMsg = "上界不可小于下界";
      }
    }
    return errMsg;
  }

  bool applyFieldsDataToModel() {
    if (validateAllFields()) {
      if (!useTimeBound && condition.ranges.length > 1) {
        condition.removeRange(1);
      } else if (useTimeBound && condition.ranges.length < 2) {
        condition.addRange(1, 1);
      }

      fieldsSetting.forEach((key, setting) {
        setting['setter']();
      });

      return true;
    }
    return false;
  }

  void resetAllFields() {
    useTimeBound = condition.ranges.length > 1;

    fieldsSetting.forEach((key, setting) {
      setting['reset']();
    });
  }

  bool validateAllFields() {
    return fieldsSetting.entries
        .map((e) => e.value['key'].currentState?.validate() ?? true)
        .fold(true, (prev, e) => prev && e);
  }

  void _initFieldsSetting() {
    fieldsSetting["score"] = {
      "key": GlobalKey<FormFieldState>(
          debugLabel: "question eval condition scoreKey"),
      "ctrl": TextEditingController(),
      "validator": scoreValidator,
      "reset": () =>
          fieldsSetting["score"]!['ctrl'].text = condition.score.toString(),
      "setter": () =>
          condition.score = double.parse(fieldsSetting["score"]!['ctrl'].text),
    };
    fieldsSetting["mainLowBound"] = {
      "key": GlobalKey<FormFieldState>(
          debugLabel: "question eval condition mainLowBoundKey"),
      "ctrl": TextEditingController(),
      "validator": mainLowBoundValidator,
      "reset": () => fieldsSetting["mainLowBound"]!['ctrl'].text =
          condition.ranges[0]['lowBound'].toString(),
      "setter": () => condition.ranges[0]['lowBound'] =
          num.parse(fieldsSetting["mainLowBound"]!['ctrl'].text),
    };
    fieldsSetting["mainHighBound"] = {
      "key": GlobalKey<FormFieldState>(
          debugLabel: "question eval condition mainHighBoundKey"),
      "ctrl": TextEditingController(),
      "validator": mainHighBoundValidator,
      "reset": () => fieldsSetting["mainHighBound"]!['ctrl'].text =
          condition.ranges[0]['highBound'].toString(),
      "setter": () => condition.ranges[0]['highBound'] =
          num.parse(fieldsSetting["mainHighBound"]!['ctrl'].text),
    };
    fieldsSetting["timeLowBound"] = {
      "key": GlobalKey<FormFieldState>(
          debugLabel: "question eval condition timeLowBoundKey"),
      "ctrl": TextEditingController(),
      "validator": timeLowBoundValidator,
      "reset": () {
        if (useTimeBound) {
          fieldsSetting["timeLowBound"]!['ctrl'].text =
              condition.ranges[1]['lowBound'].toString();
        }
      },
      "setter": () {
        if (useTimeBound) {
          condition.ranges[1]['lowBound'] =
              num.parse(fieldsSetting["timeLowBound"]!['ctrl'].text);
        }
      }
    };
    fieldsSetting["timeHighBound"] = {
      "key": GlobalKey<FormFieldState>(
          debugLabel: "question eval condition timeHighBoundKey"),
      "ctrl": TextEditingController(),
      "validator": timeHighBoundValidator,
      "reset": () {
        if (useTimeBound) {
          fieldsSetting["timeHighBound"]!['ctrl'].text =
              condition.ranges[1]['highBound'].toString();
        }
      },
      "setter": () {
        if (useTimeBound) {
          condition.ranges[1]['highBound'] =
              num.parse(fieldsSetting["timeHighBound"]!['ctrl'].text);
        }
      },
    };
  }

  void resetState() {
    useTimeBound = false;
    currEvalRule = widget.evalRule;
    condition =
        widget.condition ?? (EvalCondition(score: 10.0)..addRange(1, 1));

    resetAllFields();
  }

  @override
  void initState() {
    super.initState();

    _initFieldsSetting();

    resetState();
  }

  @override
  Widget build(BuildContext context) {
    if (currEvalRule != widget.evalRule) {
      resetState();
    }

    initStyles(context);

    List<Widget> formFields = [
      Row(
        children: [
          Text(
            "是否经过提示",
            style: commonStyles?.bodyStyle,
          ),
          Checkbox(
              value: isHinted,
              onChanged: (bool? value) {
                setState(() {
                  isHinted = value ?? false;
                  condition.isHinted = isHinted;
                });
              }),
        ],
      ),
      const SizedBox(
        height: 16,
      ),
      buildInputFormField(
        '${widget.scoreConditionName}下界：',
        fieldsSetting['mainLowBound']!['key'],
        fieldsSetting['mainLowBound']!['ctrl'],
        fieldsSetting['mainLowBound']!['validator'],
        commonStyles: commonStyles,
      ),
      const SizedBox(
        height: 16,
      ),
      buildInputFormField(
        '${widget.scoreConditionName}上界：',
        fieldsSetting['mainHighBound']!['key'],
        fieldsSetting['mainHighBound']!['ctrl'],
        fieldsSetting['mainHighBound']!['validator'],
        commonStyles: commonStyles,
      ),
      const SizedBox(
        height: 16,
      ),
      Row(
        children: [
          Text(
            "作答时间限制",
            style: commonStyles?.bodyStyle,
          ),
          Checkbox(
              value: useTimeBound,
              onChanged: (bool? value) {
                setState(() {
                  useTimeBound = value ?? false;
                });
              }),
        ],
      ),
      const SizedBox(
        height: 16,
      ),
    ];

    if (useTimeBound) {
      formFields.addAll([
        buildInputFormField(
          '作答时间下界：',
          fieldsSetting['timeLowBound']!['key'],
          fieldsSetting['timeLowBound']!['ctrl'],
          fieldsSetting['timeLowBound']!['validator'],
          commonStyles: commonStyles,
        ),
        const SizedBox(
          height: 16,
        ),
        buildInputFormField(
          '作答时间上界：',
          fieldsSetting['timeHighBound']!['key'],
          fieldsSetting['timeHighBound']!['ctrl'],
          fieldsSetting['timeHighBound']!['validator'],
          commonStyles: commonStyles,
        ),
        const SizedBox(
          height: 16,
        ),
      ]);
    }

    formFields.add(
      buildInputFormField(
        '满足条件时得分：',
        fieldsSetting['score']!['key'],
        fieldsSetting['score']!['ctrl'],
        fieldsSetting['score']!['validator'],
        commonStyles: commonStyles,
      ),
    );

    return buildSimpleActionDialog(context,
        title: '设置得分规则',
        body: Form(
          child: Column(
            children: formFields,
          ),
        ),
        commonStyles: commonStyles, onConfirm: (context) {
      setState(() {
        if (applyFieldsDataToModel()) {
          Navigator.pop(context, condition);
        }
      });
    });
  }
}
