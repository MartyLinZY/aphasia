import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/file.dart';
import '../../../utils/http/http_common.dart';
import '../common/common.dart';

class ChoiceSettingDialog extends StatefulWidget {
  final Choice? choice;
  const ChoiceSettingDialog({super.key, this.choice});

  @override
  State<ChoiceSettingDialog> createState() => _ChoiceSettingDialogState();
}

class _ChoiceSettingDialogState extends State<ChoiceSettingDialog>  with UseCommonStyles {
  Choice? currChoice;

  final _formKey = GlobalKey<FormState>(debugLabel: "choiceFormKey");
  final _choiceNameKey = GlobalKey<FormFieldState>(debugLabel: "choiceNameKey");
  final choiceNameCtrl = TextEditingController();

  String? imageUrl;
  String? imageAssetPath;

  String? choiceNameValidator (String? value) {
    if (value == null || value == "") {
      return "选项名称不可为空";
    }
    return null;
  }

  void resetState() {
    if (widget.choice != null) {
      currChoice = widget.choice;
      imageUrl = widget.choice!.imageUrl;
      imageAssetPath = widget.choice!.imageAssetPath;
      choiceNameCtrl.text = widget.choice!.text;
    }
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  @override
  Widget build(BuildContext context) {
    if (currChoice != widget.choice) {
      resetState();
    }

    initStyles(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: buildSimpleActionDialog(
          context,
          title: "选项设置",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInputFormField("选项名称：", _choiceNameKey, choiceNameCtrl, choiceNameValidator, commonStyles: commonStyles, maxLength: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("选项图片：", style: commonStyles?.bodyStyle,),
                  ElevatedButton(
                      onPressed: () {
                        doPickFile () {
                          pickImageFile().then((imgFile) {
                            if (imgFile != null) {
                              uploadFile(imgFile, FileType.image).then((url) {
                                setState(() {
                                  imageUrl = url;
                                });
                              }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                            }
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doPickFile();
                              }
                          );
                        } else {
                          doPickFile();
                        }
                      },
                      child: Text("上传图片", style: commonStyles?.bodyStyle,)
                  ),
                  const SizedBox(width: 16,),
                  ElevatedButton(
                      onPressed: () {
                        doSelectImage() {
                          showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog()).then((url) {
                            setState(() {
                              imageUrl = url;
                            });
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "选项已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doSelectImage();
                              }
                          );
                        } else {
                          doSelectImage();
                        }
                      },
                      child: Text("已上传的图片", style: commonStyles?.bodyStyle,)
                  ),
                  const SizedBox(width: 16,),
                  ElevatedButton(
                      onPressed: () {
                        doSelectImage() {
                          showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog(isBuiltIn: true,)).then((path) {
                            setState(() {
                              imageAssetPath = path;
                              imageUrl = null;
                            });
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doSelectImage();
                              }
                          );
                        } else {
                          doSelectImage();
                        }
                      },
                      child: Text("系统内置图片", style: commonStyles?.bodyStyle,)
                  ),
                ],
              ),
              const SizedBox(height: 16,),
              buildImagePreview(imageUrl: imageUrl, imageAssetPath: imageAssetPath, commonStyles: commonStyles),
              const SizedBox(height: 16,),
              imageUrl == null && imageAssetPath == null ? const SizedBox.shrink() : ElevatedButton(
                onPressed: () {
                  setState(() {
                    imageUrl = null;
                    imageAssetPath = null;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
                child: Text("移除图片", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor), ),
              ),
            ],
          ),
          commonStyles: commonStyles,
          onConfirm: (context) {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, Choice(imageUrl: imageUrl, imageAssetPath: imageAssetPath, text: choiceNameCtrl.text));
            }
          }
      ),
    );
  }
}

class ItemSlotEditDialog extends StatefulWidget {
  final ItemSlot slot;
  final int slotIndex;
  final EvalCommandQuestionByCorrectActionCount rule;
  const ItemSlotEditDialog({super.key, required this.slot, required this.rule, required this.slotIndex});

  @override
  State<ItemSlotEditDialog> createState() => _ItemSlotEditDialogState();
}

class _ItemSlotEditDialogState extends State<ItemSlotEditDialog> with UseCommonStyles{
  // 用于判断dialog外部状态是否改变过
  ItemSlot? currSlot;
  final _itemNameFieldKey = GlobalKey<FormFieldState>(debugLabel: "itemNameFieldKey");
  final itemNameCtrl = TextEditingController();
  String? imageUrl;
  String? imageAssetPath;

  void resetState() {
    currSlot = widget.slot;
    imageUrl = currSlot?.itemImageUrl;
    imageAssetPath = currSlot?.itemImageAssetPath;
    itemNameCtrl.text = currSlot?.itemName ?? "";
  }

  String? itemNameValidator (String? value) {
    if (value == null || value == "") {
      return "物体名称不可为空";
    } else {
      int index = widget.rule.indexOfItemName(value);
      if (index != -1) {
        return "物体名称不能重复，当前名称与第${index+1}个区域内物体重复";
      }
    }
    return null;
  }

  @override
  void initState() {
    resetState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (currSlot != widget.slot) {
      resetState();
    }

    initStyles(context);

    return  Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: buildSimpleActionDialog(
          context,
          title: "操作区域设置",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  confirm(context, title: "确认", body: "确认要清空该区域吗", commonStyles: commonStyles,
                      onConfirm: (context) {
                        // 关闭confirm dialog
                        Navigator.pop(context);
                        // 关闭操作区域设置dialog
                        Navigator.pop(context, ItemSlot());
                      }
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
                child: Text("清空区域", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor),),
              ),
              const Divider(),
              buildInputFormField("物体名称：", _itemNameFieldKey, itemNameCtrl, itemNameValidator, commonStyles: commonStyles, maxLength: 20, errorMaxLines: 2, width: 200),
              Wrap(
                runSpacing: 16.0,
                children: [
                  Text("物体示意图：", style: commonStyles?.bodyStyle,),
                  ElevatedButton(
                      onPressed: () {
                        doPickFile () {
                          pickImageFile().then((imgFile) {
                            if (imgFile != null) {
                              uploadFile(imgFile, FileType.image).then((url) {
                                setState(() {
                                  imageUrl = url;
                                });
                              }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                            }
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doPickFile();
                              }
                          );
                        } else {
                          doPickFile();
                        }
                      },
                      child: Text("上传图片", style: commonStyles?.bodyStyle,)
                  ),
                  const SizedBox(width: 16,),
                  ElevatedButton(
                      onPressed: () {
                        doSelectImage() {
                          showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog()).then((url) {
                            setState(() {
                              imageUrl = url;
                              imageAssetPath = null;
                            });
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doSelectImage();
                              }
                          );
                        } else {
                          doSelectImage();
                        }
                      },
                      child: Text("已上传的图片", style: commonStyles?.bodyStyle,)
                  ),
                  const SizedBox(width: 16,),
                  ElevatedButton(
                      onPressed: () {
                        doSelectImage() {
                          showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog(isBuiltIn: true,)).then((path) {
                            setState(() {
                              imageAssetPath = path;
                              imageUrl = null;
                            });
                          });
                        }
                        if (imageUrl != null || imageAssetPath != null) {
                          confirm(context, title: "确认", body: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                Navigator.pop(context);
                                doSelectImage();
                              }
                          );
                        } else {
                          doSelectImage();
                        }
                      },
                      child: Text("系统内置图片", style: commonStyles?.bodyStyle,)
                  ),
                ],
              ),
              const SizedBox(height: 16,),
              buildImagePreview(imageUrl: imageUrl, imageAssetPath: imageAssetPath, commonStyles: commonStyles),
              const SizedBox(height: 16,),
              imageUrl == null && imageAssetPath == null ? const SizedBox.shrink() : ElevatedButton(
                onPressed: () {
                  setState(() {
                    imageUrl = null;
                    imageAssetPath = null;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
                child: Text("移除图片", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor), ),
              ),
            ],
          ),
          commonStyles: commonStyles,
          onConfirm: (context) {
            if (_itemNameFieldKey.currentState!.validate() && (imageUrl != null || imageAssetPath != null)) {
              Navigator.pop(context, ItemSlot(itemImageUrl: imageUrl, itemImageAssetPath: imageAssetPath, itemName: itemNameCtrl.text));
            }

            if (imageUrl == null && imageAssetPath == null) {
              toast(context, msg: "请上传一张图片或从已上传的图片或者系统内置图案中选择一张图片作为物体的图片", btnText: "确认");
            }
          }
      ),
    );
  }
}

class QuestionScoreConditionEditDialog extends StatefulWidget {
  final EvalCondition? condition;
  final QuestionEvalRule evalRule;
  final String scoreConditionName;
  const QuestionScoreConditionEditDialog({super.key, this.condition, required this.scoreConditionName, required this.evalRule});

  @override
  State<QuestionScoreConditionEditDialog> createState() => _QuestionScoreConditionEditDialogState();
}

class _QuestionScoreConditionEditDialogState extends State<QuestionScoreConditionEditDialog> with UseCommonStyles {
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
      if (num > (double.tryParse(fieldsSetting["mainHighBound"]!['ctrl'].text) ?? double.infinity)) {
        errMsg = "下界不可大于上界";
      }
    }
    return errMsg;
  }

  String? mainHighBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num < (double.tryParse(fieldsSetting["mainLowBound"]!['ctrl'].text) ?? 0)) {
        errMsg = "上界不可小于下界";
      }
    }
    return errMsg;
  }

  String? timeLowBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num > (double.tryParse(fieldsSetting["timeHighBound"]!['ctrl'].text) ?? double.infinity)) {
        errMsg = "下界不可大于上界";
      }
    }
    return errMsg;
  }

  String? timeHighBoundValidator(String? value) {
    String? errMsg = basicValidator(value);
    if (errMsg == null) {
      double num = double.parse(value!);
      if (num < (double.tryParse(fieldsSetting["timeLowBound"]!['ctrl'].text) ?? 0)) {
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
    return fieldsSetting.entries.map((e) => e.value['key'].currentState?.validate() ?? true).fold(true, (prev, e) => prev && e);
  }

  void _initFieldsSetting() {
    fieldsSetting["score"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "question eval condition scoreKey"),
      "ctrl": TextEditingController(),
      "validator": scoreValidator,
      "reset": () => fieldsSetting["score"]!['ctrl'].text = condition.score.toString(),
      "setter": () =>  condition.score = double.parse(fieldsSetting["score"]!['ctrl'].text),
    };
    fieldsSetting["mainLowBound"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "question eval condition mainLowBoundKey"),
      "ctrl": TextEditingController(),
      "validator": mainLowBoundValidator,
      "reset": () => fieldsSetting["mainLowBound"]!['ctrl'].text = condition.ranges[0]['lowBound'].toString(),
      "setter": () =>  condition.ranges[0]['lowBound'] = num.parse(fieldsSetting["mainLowBound"]!['ctrl'].text),
    };
    fieldsSetting["mainHighBound"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "question eval condition mainHighBoundKey"),
      "ctrl": TextEditingController(),
      "validator": mainHighBoundValidator,
      "reset": () => fieldsSetting["mainHighBound"]!['ctrl'].text = condition.ranges[0]['highBound'].toString(),
      "setter": () => condition.ranges[0]['highBound'] = num.parse(fieldsSetting["mainHighBound"]!['ctrl'].text),
    };
    fieldsSetting["timeLowBound"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "question eval condition timeLowBoundKey"),
      "ctrl": TextEditingController(),
      "validator": timeLowBoundValidator,
      "reset": () {
        if (useTimeBound) {
          fieldsSetting["timeLowBound"]!['ctrl'].text = condition.ranges[1]['lowBound'].toString();
        }
      },
      "setter": () {
        if (useTimeBound) {
          condition.ranges[1]['lowBound'] = num.parse(fieldsSetting["timeLowBound"]!['ctrl'].text);
        }
      }
    };
    fieldsSetting["timeHighBound"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "question eval condition timeHighBoundKey"),
      "ctrl": TextEditingController(),
      "validator": timeHighBoundValidator,
      "reset": () {
        if (useTimeBound) {
          fieldsSetting["timeHighBound"]!['ctrl'].text = condition.ranges[1]['highBound'].toString();
        }
      },
      "setter": () {
        if (useTimeBound) {
          condition.ranges[1]['highBound'] = num.parse(fieldsSetting["timeHighBound"]!['ctrl'].text);
        }
      },
    };
  }

  void resetState() {
    useTimeBound = false;
    currEvalRule = widget.evalRule;
    condition = widget.condition ?? (EvalCondition(score: 10.0)..addRange(1, 1));

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
          Text("是否经过提示", style: commonStyles?.bodyStyle,),
          Checkbox(value: isHinted, onChanged: (bool? value) {
            setState(() {
              isHinted = value ?? false;
              condition.isHinted = isHinted;
            });
          }),
        ],
      ),
      const SizedBox(height: 16,),
      buildInputFormField('${widget.scoreConditionName}下界：', fieldsSetting['mainLowBound']!['key'], fieldsSetting['mainLowBound']!['ctrl'], fieldsSetting['mainLowBound']!['validator'],
        commonStyles: commonStyles,
      ),
      const SizedBox(height: 16,),
      buildInputFormField('${widget.scoreConditionName}上界：', fieldsSetting['mainHighBound']!['key'], fieldsSetting['mainHighBound']!['ctrl'], fieldsSetting['mainHighBound']!['validator'],
        commonStyles: commonStyles,
      ),
      const SizedBox(height: 16,),
      Row(
        children: [
          Text("作答时间限制", style: commonStyles?.bodyStyle,),
          Checkbox(value: useTimeBound, onChanged: (bool? value) {
            setState(() {
              useTimeBound = value ?? false;
            });
          }),
        ],
      ),
      const SizedBox(height: 16,),
    ];

    if (useTimeBound) {
      formFields.addAll([
        buildInputFormField('作答时间下界：', fieldsSetting['timeLowBound']!['key'], fieldsSetting['timeLowBound']!['ctrl'], fieldsSetting['timeLowBound']!['validator'],
          commonStyles: commonStyles,
        ),
        const SizedBox(height: 16,),
        buildInputFormField('作答时间上界：', fieldsSetting['timeHighBound']!['key'], fieldsSetting['timeHighBound']!['ctrl'], fieldsSetting['timeHighBound']!['validator'],
          commonStyles: commonStyles,
        ),
        const SizedBox(height: 16,),
      ]);
    }

    formFields.add(buildInputFormField('满足条件时得分：', fieldsSetting['score']!['key'], fieldsSetting['score']!['ctrl'], fieldsSetting['score']!['validator'],
      commonStyles: commonStyles,
    ),);

    return buildSimpleActionDialog(context,
      title: '设置得分规则',
      body: Form(
        child: Column(
          children: formFields,
        ),
      ),
      commonStyles: commonStyles,
      onConfirm: (context) {
        setState(() {
          if (applyFieldsDataToModel()) {
            Navigator.pop(context, condition);
          }
        });
      }
    );
  }

}