import 'package:aphasia_recovery/enum/fake_reflection.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/io/assets.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/widgets/ui/common/common.dart';
import 'package:flutter/material.dart';

import '../../../mixin/eval_rule_mixin.dart';
import 'doctor_audio_setting_dialog.dart';
import 'doctor_exam_question_rule_edit.dart';
import 'question_edit_steps/hint_rule_step.dart';
import 'question_edit_steps/question_edit_form_widgets.dart';
import 'question_edit_steps/question_type_step.dart';

class DoctorExamQuestionEditPage extends StatefulWidget {
  final Question? question;
  const DoctorExamQuestionEditPage({super.key, this.question});

  @override
  State<DoctorExamQuestionEditPage> createState() => _DoctorExamQuestionEditPageState();
}

class _DoctorExamQuestionEditPageState extends State<DoctorExamQuestionEditPage> with UseCommonStyles, TextFieldCommonValidators {
  static const double widgetsElevation = 16.0;
  static const double listTileCommonHeight = 32;

  bool requesting = false;

  // stepper相关变量
  List<Step> steps = [];
  int currStep = 0;

  // 总表单相关变量
  final GlobalKey<FormState> _formKey = GlobalKey(debugLabel: "创建新题目Form");

  // 用于记录用户对不同题型的编辑状态
  AudioQuestion? audioQuestionBackup;
  ChoiceQuestion? choiceQuestionBackup;
  CommandQuestion? commandQuestionBackup;
  WritingQuestion? writingQuestionBackup;
  ItemFindingQuestion? itemFindingQuestionBackup;

  /// 当前正在编辑的题目
  late Question currQuestion;

  // 题目基本信息编辑相关变量
  final _aliasKey = GlobalKey<FormFieldState>(debugLabel: "questionAliasKey");
  final _questionTextKey = GlobalKey<FormFieldState>(debugLabel: "questionTextKey");
  final _omitTimeKey = GlobalKey<FormFieldState>(debugLabel: "question image omit time Key");
  TextEditingController aliasCtrl = TextEditingController();
  TextEditingController questionTextCtrl = TextEditingController();
  TextEditingController omitTimeCtrl = TextEditingController();

  bool validateBasicInfoFields() {
    final aliasValid = _aliasKey.currentState!.validate();
    final questionTextValid = _questionTextKey.currentState!.validate();
    final omitTimeValid = _omitTimeKey.currentState?.validate() ?? true;

    return aliasValid && questionTextValid && omitTimeValid;
  }

  bool applyBasicInfoFieldsToModel() {
    if (validateBasicInfoFields()) {
      currQuestion.alias = aliasCtrl.text;
      currQuestion.questionText = questionTextCtrl.text;
      currQuestion.omitImageAfterSeconds = int.parse(omitTimeCtrl.text);
      return true;
    }
    return false;
  }

  void resetBasicInfoFields() {
    aliasCtrl.text = currQuestion.alias ?? "";
    questionTextCtrl.text = currQuestion.questionText ?? "";
    omitTimeCtrl.text = currQuestion.omitImageAfterSeconds.toString();
  }

  // 打分规则设置编辑相关变量
  final Map<String, Map<String, dynamic>> ruleFieldsSetting = {};

  String? keywordValidator(String? value) {
    if (value == null || value == "") {
      return "关键词不可为空";
    } else if (!isChineseString(value)) {
      return "请输入汉字";
    } else if (value.length > 15) {
      return "请将关键词长度控制在15个字符以内";
    } else {
      return null;
    }
  }

  String? fullScoreValidator(String? value) {
    if (value == null || value == "") {
      return "题目的满分值不可为空";
    } else {
      double score = double.tryParse(value) ?? 0;
      if (score <= 0) {
        return "请输入正数";
      }

      return null;
    }
  }

  String? defaultScoreValidator(String? value) {
    if (value == null || value == "") {
      return "题目的默认得分不可为空";
    } else {
      double score = double.tryParse(value) ?? 0;
      if (score < 0) {
        return "请输入非负数";
      } else {
        double? fullScore = double.tryParse(ruleFieldsSetting['fullScore']!['ctrl'].text);
        if (fullScore != null && score > fullScore) {
          return "题目的默认得分不可大于满分值";
        }

        return null;
      }
    }
  }

  String? timeLimitValidator(String? value) {
    if (value == null || value == "") {
      return "题目作答限时不可为空";
    } else {
      int score = int.tryParse(value) ?? 0;
      if (score <= 0) {
        return "请输入正整数";
      }
      return null;
    }
  }

  String? omitTimeValidator (String? value) {
    String? errMsg;
    if (currQuestion.imageUrl != null) {
      errMsg = notEmptyValidator("题干图片展示时间")(value);
      errMsg ??= needIntValidator(value);
      if (errMsg == null) {
        int num = int.parse(value!);
        if (num != -1 && num < 1) {
          return "请输入-1或大于0的整数 ";
        }
      }
    }
    return errMsg;
  }
  // 题型特有规则编辑页相关变量
  List<DropdownMenuEntry<Type>> ruleDropdownMenuEntries = [];

  String? aliasValidator(String? value) {
    if (value != null && value.length > 20) {
      return "请将题目名称长度控制在20个字符以内";
    }

    return null;
  }

  String? questionTextValidator(String? value) {
    if (value != null && value.length > 50) {
      return "请将题干文本长度控制在50个字符以内";
    }
    return null;
  }

  /// 如果[useQuestion] != null，[questionType]会被忽略
  void resetQuestionStates(Type questionType, {Question? useQuestion}) {
    if (useQuestion != null) {
      questionType = useQuestion.runtimeType;
    }

    switch (questionType) {
      case AudioQuestion:
        audioQuestionBackup ??= useQuestion == null ? AudioQuestion() : useQuestion.copy() as AudioQuestion;
        currQuestion = audioQuestionBackup!;
        _buildEvalRuleDropdownMenuEntries(AudioQuestion.availableEvalRuleTypes());
        break;
      case ChoiceQuestion:
        choiceQuestionBackup ??= useQuestion == null ? ChoiceQuestion() : useQuestion.copy() as ChoiceQuestion;
        currQuestion = choiceQuestionBackup!;
        _buildEvalRuleDropdownMenuEntries(ChoiceQuestion.availableEvalRuleTypes());
        break;
      case CommandQuestion:
        commandQuestionBackup ??= useQuestion == null ? CommandQuestion() : useQuestion.copy() as CommandQuestion;
        currQuestion = commandQuestionBackup!;
        _buildEvalRuleDropdownMenuEntries(CommandQuestion.availableEvalRuleTypes());
        break;
      case WritingQuestion:
        writingQuestionBackup ??= useQuestion == null ? WritingQuestion() : useQuestion.copy() as WritingQuestion;
        currQuestion = writingQuestionBackup!;
        _buildEvalRuleDropdownMenuEntries(WritingQuestion.availableEvalRuleTypes());
        break;
      case ItemFindingQuestion:
        itemFindingQuestionBackup ??= useQuestion == null ? ItemFindingQuestion() : useQuestion.copy() as ItemFindingQuestion;
        currQuestion = itemFindingQuestionBackup!;
        _buildEvalRuleDropdownMenuEntries(ItemFindingQuestion.availableEvalRuleTypes());
        break;
      default:
        throw UnimplementedError("无效的Question Type：$questionType");
    }
    resetBasicInfoFields();
    resetEvalRuleSettingState();
  }

  void _buildEvalRuleDropdownMenuEntries(Map<Type, dynamic> availableRulesMap) {
    ruleDropdownMenuEntries = availableRulesMap
        .entries
        .map((e) => DropdownMenuEntry(value: e.key, label: e.value[ClassProperties.displayName])).toList();
  }

  bool validateAndApplyChangesBeforeStepChange() {
    if (currStep == 1) {
      if (!applyBasicInfoFieldsToModel()) {
        return false;
      }

      String questionText = currQuestion.questionText ?? "";
      if (questionText == "" && currQuestion.audioUrl == null) {
        toast(context, msg: "请至少设置一个有效的题干文本或设置一个题干音频", btnText: "确认");
        return false;
      }
    } else if (currStep == 2) {
      if (!setEvalRuleSetting()) {
        return false;
      }

      String? errMsg = currQuestion.evalRule!.checkSetting();
      if (errMsg != null) {
        toast(context, msg: errMsg, btnText: "确认");
        return false;
      }
    }

    return true;
  }


  // 下面三个方法需要同步修改
  void resetEvalRuleSettingState() {
    ruleFieldsSetting.forEach((key, setting) {
      setting['reset']();
    });
  }

  bool validateEvalRuleSetting() {
    // 如果currentState为null说明这个当前规则没有用到这个field，需要跳过这个field，所以默认返回true
    return ruleFieldsSetting.entries.map((e) => e.value['key'].currentState?.validate() ?? true).fold(true, (prev, e) => prev && e);
  }

  bool setEvalRuleSetting() {
    if (validateEvalRuleSetting()) {
      ruleFieldsSetting.forEach((key, value) => value['setter']());
      return true;
    }

    return false;
  }

  void _initEvalRuleSetting() {
    ruleFieldsSetting["keyword"] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "keywordFieldKey"),
      "ctrl": TextEditingController(),
      "validator": keywordValidator,
      "reset": () {
        if (currQuestion.evalRule is RuleKeyword) {
          ruleFieldsSetting['keyword']!['ctrl'].text = (currQuestion.evalRule as RuleKeyword).keyword;
        } else if (currQuestion.evalRule is KeywordList) {
          ruleFieldsSetting['keyword']!['ctrl'].text = "";
        }
      },
      "setter": () {
        if (currQuestion.evalRule is RuleKeyword) {
          (currQuestion.evalRule as RuleKeyword).keyword = ruleFieldsSetting['keyword']!['ctrl'].text;
        }
      }
    };
    ruleFieldsSetting['timeLimit'] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "timeLimitFieldKey"),
      "ctrl": TextEditingController(),
      "validator": timeLimitValidator,
      "reset": () => (ruleFieldsSetting['timeLimit']!['ctrl'].text = currQuestion.evalRule?.ansTimeLimit.toString() ?? ""),
      "setter": () => (currQuestion.evalRule!.timeLimit = int.parse(ruleFieldsSetting['timeLimit']!['ctrl'].text)),
    };
    ruleFieldsSetting['fullScore'] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "fullScoreFieldKey"),
      "ctrl": TextEditingController(),
      "validator": fullScoreValidator,
      "reset": () => (ruleFieldsSetting['fullScore']!['ctrl'].text = currQuestion.evalRule?.fullScore.toString() ?? ""),
      "setter": () => (currQuestion.evalRule!.fullScore = double.parse(ruleFieldsSetting['fullScore']!['ctrl'].text)),
    };
    ruleFieldsSetting['defaultScore'] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "defaultScoreFieldKey"),
      "ctrl": TextEditingController(),
      "validator": defaultScoreValidator,
      "reset": () => (ruleFieldsSetting['defaultScore']!['ctrl'].text = currQuestion.evalRule?.defaultScore.toString() ?? ""),
      "setter": () => (currQuestion.evalRule!.defaultScore = double.parse(ruleFieldsSetting['defaultScore']!['ctrl'].text)),
    };
    ruleFieldsSetting['answerText'] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "answerTextFieldKey"),
      "ctrl": TextEditingController(),
      "validator": (String? value) {
        value ??= "";
        if (value == "") {
          return "答案文本不可为空";
        }
        return null;
      },
      "reset": () {
        if (currQuestion.evalRule is LongAnswer) {
          ruleFieldsSetting['answerText']!['ctrl'].text = (currQuestion.evalRule as LongAnswer).answerText;
        }
      },
      "setter": () {
        if (currQuestion.evalRule is LongAnswer) {
          (currQuestion.evalRule as LongAnswer).answerText = ruleFieldsSetting['answerText']!['ctrl'].text;
        }
      },
    };
    ruleFieldsSetting['invalidActionPunishment'] = {
      "key": GlobalKey<FormFieldState>(debugLabel: "invalidActionPunishmentFieldKey"),
      "ctrl": TextEditingController(),
      "validator": (String? value) {
        value ??= "";
        if (value == "") {
          return "无效动作扣分值不可为空";
        } else {
          double? punish = double.tryParse(value);
          if (punish == null || punish < 0) {
            return "请输入一个非负数";
          } else {
            double? fullScore = double.tryParse(ruleFieldsSetting['fullScore']!['ctrl'].text);
            if (fullScore != null && punish > fullScore) {
              return "扣分值不可大于题目满分值";
            }
          }
        }
        return null;
      },
      "reset": () {
        if (currQuestion.evalRule is EvalCommandQuestionByCorrectActionCount) {
          ruleFieldsSetting['invalidActionPunishment']!['ctrl'].text = (currQuestion.evalRule as EvalCommandQuestionByCorrectActionCount).invalidActionPunishment.toString();
        }
      },
      "setter": () {
        if (currQuestion.evalRule is EvalCommandQuestionByCorrectActionCount) {
          (currQuestion.evalRule as EvalCommandQuestionByCorrectActionCount).invalidActionPunishment = double.parse(ruleFieldsSetting['invalidActionPunishment']!['ctrl'].text);
        }
      },
    };
  }

  @override
  void initState() {
    _initEvalRuleSetting();

    if (widget.question != null) {
      resetQuestionStates(widget.question.runtimeType, useQuestion: widget.question);
    } else {
      resetQuestionStates(AudioQuestion);
    }

    currStep = 0;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    steps = createSteps(context);

    return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: Text(widget.question != null ? "编辑题目" : "创建新题目", style: commonStyles?.titleStyle,)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: currStep,
              controlsBuilder: _actionBtnBuilder,
              stepIconBuilder: _stepIconBuilder,
              steps: steps,
              onStepTapped: (int index) {
                setState(() {
                  if (index > currStep && !validateAndApplyChangesBeforeStepChange()) {
                    return;
                  }

                  currStep = index;
                  resetCurrentStepStates();
                });
              },
            ),
          )
        )
    );
  }

  List<Step> createSteps(BuildContext context) {
    return <Step>[
      _buildFirstStep(context),
      _buildSecondStep(context),
      _buildThirdStep(context),
      _buildFourthStep(context),
    ];
  }

  Step _buildFirstStep(BuildContext context) {
    return Step(
      title: Text("题目类型", style: commonStyles?.bodyStyle),
      content: QuestionTypeStep(
        currentType: currQuestion.runtimeType,
        commonStyles: commonStyles!,
        cardElevation: widgetsElevation,
        onTypeSelected: (type) => setState(() => resetQuestionStates(type)),
      ),
    );
  }

  Step _buildSecondStep(BuildContext context) {
    return Step(
      title: Text("基础设置", style: commonStyles?.bodyStyle),
      content: wrappedByCardInner(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("题目基础设置：", style: commonStyles?.titleStyle),
            const Divider(height: 24, thickness: 0.5),
            DecoratedTextField(
              label: "题目名称：",
              controller: aliasCtrl,
              fieldKey: _aliasKey,
              validator: aliasValidator,
              maxLength: 20,
              commonStyles: commonStyles!,
            ),
            const SizedBox(height: 16),
            DecoratedTextField(
              label: "题干文本：",
              controller: questionTextCtrl,
              fieldKey: _questionTextKey,
              validator: questionTextValidator,
              maxLength: 50,
              commonStyles: commonStyles!,
            ),
            const SizedBox(height: 16),
            MediaSection(
              title: "题干音频设置",
              value: currQuestion.audioUrl,
              setAction: _handleSetAudio,
              clearAction: _handleClearAudio,
              icon: Icons.audiotrack,
              commonStyles: commonStyles!,
            ),
            const SizedBox(height: 16),
            MediaSection(
              title: "题干图片设置",
              value: currQuestion.imageUrl,
              setAction: _handleSetImage,
              clearAction: _handleClearImage,
              icon: Icons.image,
              commonStyles: commonStyles!,
              extraContent: ImageOmitTimeField(
                visible: currQuestion.imageUrl != null,
                controller: omitTimeCtrl,
                fieldKey: _omitTimeKey,
                validator: omitTimeValidator,
                commonStyles: commonStyles!,
              ),
            ),
          ],
        ),
      )
    );
  }

  void _handleSetAudio() {
    showDialog<String?>(
      context: context,
      builder: (context) => AudioSettingDialog(uploadedAudioUrl: currQuestion.audioUrl),
    ).then((fileUrl) {
      if (fileUrl != null) {
        setState(() => currQuestion.audioUrl = fileUrl);
      }
    });
  }

  void _handleClearAudio() {
    confirm(
      context,
      title: "确认",
      body: "确认要删除已经设置的音频吗？",
      commonStyles: commonStyles,
      onConfirm: (context) {
        Navigator.pop(context);
        setState(() => currQuestion.audioUrl = null);
      }
    );
  }

  void _handleSetImage() {
    String? imageAssetPath = isImageUrlAssets(currQuestion.imageUrl) 
        ? currQuestion.imageUrl 
        : null;
    String? imageUrl = !isImageUrlAssets(currQuestion.imageUrl)
        ? currQuestion.imageUrl
        : null;

    showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => SelectImagesDialog(
        imageAssetPath: imageAssetPath,
        imageUrl: imageUrl,
        commonStyles: commonStyles,
      ),
    ).then((map) {
      if (map != null && (map['imageUrl'] != null || map['imageAssetPath'] != null)) {
        setState(() {
          currQuestion.imageUrl = map['imageUrl'] ?? map['imageAssetPath'];
        });
      }
    });
  }

  void _handleClearImage() {
    confirm(
      context,
      title: "确认",
      body: "确认要删除已经设置的图片吗？",
      commonStyles: commonStyles,
      onConfirm: (context) {
        Navigator.pop(context);
        setState(() {
          currQuestion.imageUrl = null;
          currQuestion.omitImageAfterSeconds = -1;
        });
      }
    );
  }

  Step _buildThirdStep(BuildContext context) {
    return Step(
        title: Text("评分规则", style: commonStyles?.bodyStyle,),
        content: wrappedByCardInner(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("评分规则设置", style: commonStyles?.titleStyle,),
                const SizedBox(height: 16,),
                Row(
                  children: [
                    // 规则类型下拉选择器
                    Text("评分规则：", style: commonStyles?.bodyStyle,),
                    DropdownMenu(
                        initialSelection: currQuestion.evalRule.runtimeType,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        onSelected: (Type? value) {
                          assert(value != null);
                          setState(() {
                            switch (currQuestion.runtimeType) {
                              case AudioQuestion:
                                currQuestion.evalRule = AudioQuestion.availableEvalRuleTypes()[value][ClassProperties.constructor]();
                                break;
                              case ChoiceQuestion:
                                currQuestion.evalRule = ChoiceQuestion.availableEvalRuleTypes()[value][ClassProperties.constructor]();
                                break;
                              case CommandQuestion:
                                currQuestion.evalRule = CommandQuestion.availableEvalRuleTypes()[value][ClassProperties.constructor]();
                                break;
                              case WritingQuestion:
                                currQuestion.evalRule = WritingQuestion.availableEvalRuleTypes()[value][ClassProperties.constructor]();
                                break;
                              case ItemFindingQuestion:
                                currQuestion.evalRule = ItemFindingQuestion.availableEvalRuleTypes()[value][ClassProperties.constructor]();
                                break;
                              default:
                                throw UnimplementedError("无效的Question Type：$value");
                            }
                            resetBasicInfoFields();
                            resetEvalRuleSettingState();
                          });
                        },
                        dropdownMenuEntries: ruleDropdownMenuEntries
                    ),
                  ],
                ),
                const Divider(),
                DoctorExamQuestionRuleEditSubPage(currQuestion: currQuestion, ruleSetting: ruleFieldsSetting),
              ],
            )
        )
    );
  }

  Step _buildFourthStep(BuildContext context) {
    return Step(
      title: Text("提示规则", style: commonStyles?.bodyStyle),
      content: HintRuleStep(
        currQuestion: currQuestion,
        requesting: requesting,
        commonStyles: commonStyles!,
        listTileCommonHeight: listTileCommonHeight,
        cardElevation: widgetsElevation,
      ),
    );
  }

  Widget wrappedByCardInner({required Widget child}) {
    return wrappedByCard(child: child, elevation: widgetsElevation);
  }

  Widget _actionBtnBuilder(BuildContext context, ControlsDetails ctrlDetail) {
    var goNextBtn = ElevatedButton(
      onPressed: () {
        setState(() {
          if (!validateAndApplyChangesBeforeStepChange()) {
            return;
          }

          currStep++;
          resetCurrentStepStates();
        });
      },
      style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor, elevation: widgetsElevation),
      child: Text("下一步", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
    );

    var goBackBtn = ElevatedButton(
      onPressed: () {
        setState(() {
          currStep--;
          resetCurrentStepStates();
        });
      },
      style: ElevatedButton.styleFrom(elevation: widgetsElevation),
      child: Text("上一步", style: commonStyles?.bodyStyle,),

    );

    List<Widget> controls = [];
    if (currStep < steps.length - 1) {
      if (currStep > 0) {
        controls.add(goBackBtn);
        controls.add(const SizedBox(width: 16,));
      }
      controls.add(goNextBtn);
    } else if (currStep == steps.length - 1) {
      controls.add(goBackBtn);
      controls.add(const SizedBox(width: 16,));
      controls.add(ElevatedButton(
        onPressed: () {
          if (requesting) {
            return;
          }

          if (!applyBasicInfoFieldsToModel()) {
            setState(() {
              currStep = 1;
            });
            return;
          }

          String questionText = currQuestion.questionText ?? "";
          if (questionText == "" && currQuestion.audioUrl == null) {
            toast(context, msg: "请至少设置一个有效的题干文本或设置一个题干音频", btnText: "确认");
            setState(() {
              currStep = 1;
            });
            return;
          }

          if (!setEvalRuleSetting()) {
            setState(() {
              currStep = 2;
            });
            return;
          }

          String? errMsg = currQuestion.evalRule!.checkSetting();
          if (errMsg != null) {
            toast(context, msg: "errMsg", btnText: "确认");
            setState(() {
              currStep = 2;
            });
            return;
          }

          doReturn(questionToReturn) {
            Navigator.pop(context, questionToReturn);
            requesting = false;
          }

          setState(() {
            requesting = true;
          });
          doReturn(currQuestion);
        },
        style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor, elevation: widgetsElevation),
        child: Text(widget.question == null ? "创建" : "保存", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
      )
      );
    } else {
      throw UnimplementedError("无效的step index：$currStep");
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0),
      child: Row(
        children: controls,
      ),
    );
  }

  void resetCurrentStepStates() {
    switch (currStep) {
      case 1:
        resetBasicInfoFields();
        break;
      case 2:
        resetEvalRuleSettingState();
        break;
      default:
        break;
    }
  }

  Widget? _stepIconBuilder(int stepIndex, StepState state) {
    Color? iconColor;
    if (stepIndex == currStep) {
      iconColor = commonStyles?.primaryColor;
    } else {
      iconColor = const Color(0x611b1b1f);
    }

    return Container(
      width: 24.0,
      height: 24.0,
        decoration: BoxDecoration(
          color: iconColor,
          shape: BoxShape.circle
        ),
        child: Center(
          child: Text("${stepIndex+1}",
            style: TextStyle(fontSize: 12.0, color: commonStyles?.onPrimaryColor,),
          ),
        )
    );
  }
}