import 'dart:math';

import 'package:aphasia_recovery/enum/fake_reflection.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/io/assets.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/widgets/ui/common/common.dart';
import 'package:flutter/material.dart';

import '../../../mixin/eval_rule_mixin.dart';
import 'doctor_exam_question_edit_dialogs.dart';
import 'doctor_exam_question_rule_edit.dart';

class DoctorExamQuestionEditPage extends StatefulWidget {
  final Question? question;
  const DoctorExamQuestionEditPage({super.key, this.question});

  @override
  State<DoctorExamQuestionEditPage> createState() => _DoctorExamQuestionEditPageState();
}

class _DoctorExamQuestionEditPageState extends State<DoctorExamQuestionEditPage> with UseCommonStyles, TextFieldCommonValidators {
  static const double widgetsElevation = 16.0;
  static const double listTileCommonHeight = 32;

  static const Map<Type, String> questionIntroduction = {
    AudioQuestion: "录音作答题：患者通过录音作答。可选择关键词，关键词列表，流畅度分析等方式对患者作答评分。",
    ChoiceQuestion: "选择题：患者通过点击选项作答。可设置2-20个选项。",
    CommandQuestion: "指令题：患者通过点击或拖动物体作答。可设置多个物体并设置指令，系统按照患者完成指令的程度打分。",
    WritingQuestion: "书写题：患者通过手写作答。可以设置关键词或关键词列表，系统自动识别患者手写内容并与关键词进行匹配打分。",
    ItemFindingQuestion: "场景寻物题：在题目图片中圈出物体，患者通过点击图片作答，系统自动判断患者是否正确点击指定物体",
  };

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

    // currStep = 3;
    currStep = 0;

    // TODO: remove test code
    // 场景寻物测试
    // currQuestion.evalRule!.conditions.add(EvalCondition(score: 10.0)..addRange(5, 5)..addRange(0, 10));
    // currQuestion.evalRule!.conditions.add(EvalCondition(score: 20.0)..addRange(5, 5)..addRange(11, 20));
    // currQuestion.evalRule!.conditions.add(EvalCondition(score: 0.0)..addRange(0, 0));
    // 指令题测试
    // rule.slotCount = 20;
    // rule.slots[2] = (ItemSlot(itemName: "梳子", itemImageAssetPath: "assets/images/for_question_setting/comb.png"));
    // rule.slots[6] = (ItemSlot(itemName: "刀", itemImageAssetPath: "assets/images/for_question_setting/knife.jpg"));
    // rule.slots[8] = (ItemSlot(itemName: "锁", itemImageAssetPath: "assets/images/for_question_setting/lock.jpg"));
    // rule.slots[12] = (ItemSlot(itemName: "枪", itemImageAssetPath: "assets/images/for_question_setting/gun.jpg"));
    // 提示规则测试
    // currQuestion.evalRule!.addHintRule(HintRule(scoreHighBound: 10.0, adjustValue: 2));
    // currQuestion.evalRule!.addHintRule(HintRule(scoreHighBound: 10.0, adjustValue: 4));
    // currQuestion.evalRule!.addHintRule(HintRule(scoreHighBound: 10.0, adjustValue: 6));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    // if (widget.question != null && widget.question != currQuestion) {
    //   // TODO: 考虑一下
    //   resetQuestionStates(widget.question.runtimeType, useQuestion: widget.question);
    // }

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
      // _buildFifthStep(context)
    ];
  }

  Step _buildFirstStep(BuildContext context) {
    return Step(
        title: Text("题目类型", style: commonStyles?.bodyStyle,),
        content: wrappedByCardInner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("选择题目类型：", style: commonStyles?.titleStyle,),
              const Divider(height: 24, thickness: 0.5,),
              Row(
                children: [
                  // 题型下拉选择器
                  Text("题目类型：", style: commonStyles?.bodyStyle,),
                  DropdownMenu(
                      initialSelection: currQuestion.runtimeType,
                      requestFocusOnTap: false,
                      enableSearch: false,
                      onSelected: (Type? value) {
                        assert(value != null);
                        setState(() {
                          resetQuestionStates(value!);
                        });
                      },
                      textStyle: commonStyles?.bodyStyle,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: AudioQuestion,
                          label: AudioQuestion.questionTypeName(),
                        ),
                        DropdownMenuEntry(
                          value: ChoiceQuestion,
                          label: ChoiceQuestion.questionTypeName(),
                        ),
                        DropdownMenuEntry(
                          value: CommandQuestion,
                          label: CommandQuestion.questionTypeName(),
                        ),
                        DropdownMenuEntry(
                          value: WritingQuestion,
                          label: WritingQuestion.questionTypeName(),
                        ),
                        DropdownMenuEntry(
                          value: ItemFindingQuestion,
                          label: ItemFindingQuestion.questionTypeName(),
                        ),
                      ]
                  ),
                ],
              ),
              const SizedBox(height: 16,),
              // 题型简介
              Row(
                children: [
                  Expanded(child: Text("题型简介：${questionIntroduction[currQuestion.runtimeType]!}", style: commonStyles?.bodyStyle,)),
                ],
              ),
            ],
          ),
        )
    );
  }

  Step _buildSecondStep(BuildContext context) {
    return Step(
      title: Text("基础设置", style: commonStyles?.bodyStyle,),
      content: wrappedByCardInner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("题目基础设置：", style: commonStyles?.titleStyle,),
              const Divider(height: 24, thickness: 0.5,),
              _buildAliasField(),
              const SizedBox(height: 16,),
              _buildQuestionTextField(),
              const SizedBox(height: 16,),
              _buildAudioSetting(),
              const SizedBox(height: 16,),
              _buildImageSetting(),
            ],
          )
      )
    );
  }

  double getTextFieldWidth(BuildContext context, double textFieldMinWidth) {
    return max(MediaQuery.of(context).size.width / 4, textFieldMinWidth);
  }

  Widget _buildAliasField() {
    double textFieldMinWidth = 100.0;
    return Row(
      children: [
        Text("题目名称：", style: commonStyles?.bodyStyle,),
        Container(
          constraints: BoxConstraints(maxWidth: getTextFieldWidth(context, textFieldMinWidth), minWidth: textFieldMinWidth),
          child: TextFormField(
            key: _aliasKey,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLength: 20,
            controller: aliasCtrl,
            style: commonStyles?.bodyStyle,
            validator: aliasValidator,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTextField() {
    double textFieldMinWidth = 100;
    return Row(
      children: [
        Text("题干文本：", style: commonStyles?.bodyStyle,),
        Container(
          constraints: BoxConstraints(maxWidth: getTextFieldWidth(context, textFieldMinWidth), minWidth: textFieldMinWidth),
          child: TextFormField(
            key: _questionTextKey,
            maxLength: 50,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            controller: questionTextCtrl,
            style: commonStyles?.bodyStyle,
            validator: questionTextValidator,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSetting() {

    return Row(
      children: [
        Text("设置题干音频：", style: commonStyles?.bodyStyle,),
        ElevatedButton (
          onPressed: () {
            showDialog<String?>(context: context, builder: (context) => AudioSettingDialog(uploadedAudioUrl: currQuestion.audioUrl,))
              .then((fileUrl) {
              if (fileUrl != null) {
                setState(() {
                  currQuestion.audioUrl = fileUrl;
                });
              }
            });
          },
          child: Text("设置", style: commonStyles?.bodyStyle,),
        ),
        const SizedBox(width: 16,),
        currQuestion.audioUrl == null ? const SizedBox.shrink(): ElevatedButton(
          onPressed: () {
            confirm(context, title: "确认", body: "确认要删除已经设置的音频吗？", commonStyles: commonStyles,
              onConfirm: (context) {
                Navigator.pop(context);
                setState(() {
                  currQuestion.audioUrl = null;
                });
              }
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
          child: Text("清除已设置音频", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor), ),
        )
      ],
    );
  }

  Widget _buildImageSetting() {
    String? imageAssetPath;
    String? imageUrl;
    if (isImageUrlAssets(currQuestion.imageUrl)) {
      imageAssetPath = currQuestion.imageUrl;
    } else {
      imageUrl = currQuestion.imageUrl;
    }

    return Column(
      children: [
        Row(
          children: [
            Text("设置题干图片：", style: commonStyles?.bodyStyle,),
            ElevatedButton (
              onPressed: () {
                showDialog<Map<String, dynamic>?>(context: context, builder: (context) => SelectImagesDialog (
                  imageAssetPath: imageAssetPath,
                  imageUrl: imageUrl,
                  commonStyles: commonStyles,
                )).then((map) {
                  if(map != null) {
                    setState(() {
                      currQuestion.imageUrl = map['imageUrl'] ?? map['imageAssetPath'];
                    });
                  }
                });
              },
              child: Text("设置", style: commonStyles?.bodyStyle,),
            ),
            const SizedBox(width: 16,),
            currQuestion.imageUrl == null ? const SizedBox.shrink(): ElevatedButton(
                onPressed: () {
                  confirm(context, title: "确认", body: "确认要删除已经设置的图片吗？", commonStyles: commonStyles,
                    onConfirm: (context) {
                      Navigator.pop(context);
                      setState(() {
                        currQuestion.imageUrl = null;
                        currQuestion.omitImageAfterSeconds = -1;
                      });
                    }
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
                child: Text("清除已设置图片", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor),)
            )
          ],
        ),
        const SizedBox(height: 16,),
        currQuestion.imageUrl == null? const SizedBox.shrink() : buildInputFormField("图片展示时间（1-${Question.maxOmitTime}）：", _omitTimeKey, omitTimeCtrl, omitTimeValidator, commonStyles: commonStyles),
        currQuestion.imageUrl == null? const SizedBox.shrink() : Text("场景寻物题不需要修改该值；对于录音题，可以将该值设为-1来设置始终显示图片；对于选择题、指令题和书写题，该值最大为${Question.maxOmitTime}", style: commonStyles?.bodyStyle,),
      ],
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
    if (requesting) {
      return Step(
        title: Text("提示规则", style: commonStyles?.bodyStyle,),
        content: wrappedByCardInner(
          child: Center(
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
                  child: Text(
                    '处理中，请稍候',
                    style: commonStyles!.hintTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Step(
      title: Text("提示规则", style: commonStyles?.bodyStyle,),
      content: wrappedByCardInner(
        child: Column(
          children: [
            Text("提示规则", style: commonStyles?.titleStyle,),
            const Divider(),
            Text("提示条件列表（每道题只会触发一条提示）：", style: commonStyles?.bodyStyle,),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog<HintRule?>(
                            context: context,
                            builder: (context) => HintRuleEditDialog(question: currQuestion))
                            .then((hintRule) {
                          if (hintRule != null) {
                            setState(() {
                              currQuestion.evalRule!.addHintRule(hintRule);
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
                      child: Text("新增提示条件", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: 400,
                    child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Table(
                            border: TableBorder.all(),
                            columnWidths: const<int, TableColumnWidth> {
                              0: FlexColumnWidth(0.5),
                              4: FlexColumnWidth(1.5),
                              5: FlexColumnWidth(1.5),
                              6: FlexColumnWidth(1.0),
                            },
                            children: [
                              TableRow(
                                  children: [
                                    Center(child: Text("序号", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                                    Center(child: Text("触发提示得分下界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                                    Center(child: Text("触发提示得分上界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                                    Center(child: Text("操作", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,))
                                  ]
                              ),
                              ...currQuestion.evalRule!.hintRules.asMap().entries.map((e) {
                                final hintIndex = e.key;
                                HintRule hintRule = e.value;

                                final buttonSize = commonStyles!.isMedium || commonStyles!.isLarge ? 30.0 : 20.0;

                                return TableRow(
                                  children: [
                                    Center(child: Text((e.key + 1).toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                        child: Text(hintRule.scoreLowBound.toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                        child: Text(hintRule.scoreHighBound.toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                                      ),
                                    ),
                                    Center(
                                      child: buildListTileContentWithActionButtons(
                                          body: const SizedBox.shrink(),
                                          textAreaMaxHeight: listTileCommonHeight,
                                          textAreaMaxWidth: 0,
                                          mainAxisSize: MainAxisSize.min,
                                          buttonSize: buttonSize,
                                          commonStyles: commonStyles,
                                          moreButtons: [
                                            createActionButtonSetting(btnTooltipMsg: "编辑", btnIcon: Icon(Icons.edit, size: buttonSize,),
                                              btnAction: () {
                                                showDialog<HintRule?>(context: context,
                                                    builder: (context) => HintRuleEditDialog(question: currQuestion, hintRule: hintRule,))
                                                    .then((updated) {
                                                  if (updated != null) {
                                                    setState(() {
                                                      currQuestion.evalRule!.updateHintRule(updated: updated, index: hintIndex);
                                                    });
                                                  }
                                                });
                                              },
                                            ),
                                            createActionButtonSetting(btnTooltipMsg: "删除", btnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,size: buttonSize,),
                                              btnAction: () {
                                                confirm(context, title: "确认", body: "确认要删除该提示规则吗？", commonStyles: commonStyles,
                                                    onConfirm: (context) {
                                                      Navigator.pop(context);
                                                      setState(() {
                                                        currQuestion.evalRule!.deleteHintRule(hintIndex);
                                                      });
                                                    }
                                                );
                                              },
                                            ),
                                            createActionButtonSetting(btnTooltipMsg: "上移", btnIcon: Icon(Icons.arrow_upward, size: buttonSize,),
                                              btnAction: () {
                                                setState(() {
                                                  currQuestion.evalRule!.moveUpHintRule(hintIndex);
                                                });
                                              },
                                            ),
                                            createActionButtonSetting(btnTooltipMsg: "下移", btnIcon: Icon(Icons.arrow_downward, size: buttonSize,),
                                              btnAction: () {
                                                setState(() {
                                                  currQuestion.evalRule!.moveDownHintRule(hintIndex);
                                                });
                                              },
                                            ),
                                          ]
                                      ),
                                    )
                                  ],
                                );
                              }).toList(),
                            ],
                          );
                        }
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  Step _buildFifthStep(BuildContext context) {
    return Step(
        title: Text("基本信息", style: commonStyles?.bodyStyle,),
        content: const Placeholder()
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
          if (widget.question == null) {
            doReturn(currQuestion);
          } else {
            Question.updateQuestion(currQuestion).then((updated) {
              doReturn(updated);
            }).catchError((err) {
              requestResultErrorHandler(context, error: err);
              setState(() {
                requesting = false;
              });
              return err;
            });
          }
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