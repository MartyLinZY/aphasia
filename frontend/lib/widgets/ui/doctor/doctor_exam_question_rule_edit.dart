import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:aphasia_recovery/enum/command_actions.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:aphasia_recovery/utils/io/assets.dart';
import 'package:aphasia_recovery/utils/http/http_common.dart';
import 'package:aphasia_recovery/widgets/ui/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_recovery/mixin/eval_rule_mixin.dart';
import 'doctor_exam_question_rule_edit_dialog.dart';
import '../../../models/question/question.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../do_exam/command_question.dart';


class DoctorExamQuestionRuleEditSubPage extends StatefulWidget {
  final Question currQuestion;
  final Map<String, Map<String, dynamic>> ruleSetting;
  const DoctorExamQuestionRuleEditSubPage({super.key, required this.currQuestion, required this.ruleSetting});

  @override
  State<DoctorExamQuestionRuleEditSubPage> createState() => _DoctorExamQuestionRuleEditSubPageState();
}

class _DoctorExamQuestionRuleEditSubPageState extends State<DoctorExamQuestionRuleEditSubPage> with UseCommonStyles {

  static const double listTileCommonHeight = 32;
  
  late Question currQuestion;
  late Map<String, Map<String, dynamic>> ruleFieldsSetting;

  final keywordAdderCtrl = TextEditingController();
  final keywordAdderKey = GlobalKey<FormFieldState>();

  void resetState() {
    currQuestion = widget.currQuestion;
    ruleFieldsSetting = widget.ruleSetting;
  }

  @override
  void initState() {
    resetState();

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    if (currQuestion != widget.currQuestion) {
      resetState();
    }

    initStyles(context);
    return _buildEvalRuleSetting();
  }


  Widget _buildEvalRuleSetting() {
    var evalRule = currQuestion.evalRule!;

    // 这三个设置所有规则通用
    List<Widget> settingFields = [
      buildInputFormField("题目满分：", ruleFieldsSetting['fullScore']!['key'], ruleFieldsSetting['fullScore']!['ctrl'], ruleFieldsSetting['fullScore']!['validator'], width: 250, commonStyles: commonStyles),
      const SizedBox(height: 16,),
      buildInputFormField("题目默认得分：", ruleFieldsSetting['defaultScore']!['key'], ruleFieldsSetting['defaultScore']!['ctrl'], ruleFieldsSetting['defaultScore']!['validator'], width: 250, commonStyles: commonStyles),
      const SizedBox(height: 16,),
      buildInputFormField("答题限时（秒）：", ruleFieldsSetting['timeLimit']!['key'], ruleFieldsSetting['timeLimit']!['ctrl'], ruleFieldsSetting['timeLimit']!['validator'], width: 250, commonStyles: commonStyles),
    ];

    // 生成一些多个规则通用的设置
    if (evalRule is RuleKeyword) {
      final setting = ruleFieldsSetting['keyword']!;
      settingFields.add(const SizedBox(height: 16,));
      settingFields.add(buildInputFormField("关键词：", setting['key'], setting['ctrl'], setting['validator'], commonStyles: commonStyles));
    } 
    if (evalRule is KeywordList) {
      var keywordSetting = ruleFieldsSetting['keyword']!;
      settingFields.add(const SizedBox(height: 16,));
      var keywordListRule = evalRule as KeywordList;
      settingFields.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap (
              spacing: 8.0,
              children: [
                Text("关键词列表：", style: commonStyles?.bodyStyle,),
                ...keywordListRule.keywords.asMap().entries.map((e) => _buildKeywordItem(e.key, e.value, keywordListRule)).toList(),
              ]
          ),
          const SizedBox(height: 8,),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextFormField(
                  key: keywordAdderKey,
                  controller: keywordAdderCtrl,
                  validator: keywordSetting['validator'],
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  style: commonStyles?.bodyStyle,
                ),
              ),
              const SizedBox(width: 16,),
              ElevatedButton(
                  onPressed: () {
                    if (keywordAdderKey.currentState?.validate() ?? false) {
                      setState(() {
                        keywordListRule.keywords.add(keywordAdderCtrl.text);
                      });
                    }
                  },
                  child: Text("添加关键字", style: commonStyles?.bodyStyle,)
              )
            ],
          ),
        ],
      ));
    }

    if (evalRule is LongAnswer) {
      settingFields.add(const SizedBox(height: 16,));
      var setting = ruleFieldsSetting['answerText']!;
      settingFields.add(buildInputFormField("答案文本：", setting['key'], setting['ctrl'], setting['validator'], maxLength: 200, maxLines: 3, minLines: 2, commonStyles: commonStyles));
    }

    if (evalRule is AnswerOrder) {
      settingFields.add(const SizedBox(height: 16,));
      var answerOrderedRule = evalRule as AnswerOrder;
      settingFields.add(Row(
        children: [
          Text("要求作答顺序与答案一致：", style: commonStyles?.bodyStyle,),
          Checkbox(value: answerOrderedRule.enforceOrder, onChanged: (bool? value) {
            setState(() {
              answerOrderedRule.enforceOrder = value ?? false;
            });
          })
        ],
      ));
    }

    if (evalRule is FuzzyEvalSetting) {
      settingFields.add(const SizedBox(height: 16,));
      var fuzzyRule = evalRule as FuzzyEvalSetting;
      settingFields.add(Row(
        children: [
          Text("模糊评分：", style: commonStyles?.bodyStyle,),
          Checkbox(value: fuzzyRule.enableFuzzyEvaluation, onChanged: (bool? value) {
            setState(() {
              fuzzyRule.enableFuzzyEvaluation = value ?? false;
            });
          })
        ],
      ));
    }

    // 某些规则特有的设置或内容
    final questionType = currQuestion.evalRule.runtimeType;
    switch (questionType) {
      case EvalAudioQuestionByFluency:
        settingFields.add(const SizedBox(height: 16,));
        settingFields.add(Text("该评分方式由系统自动根据患者说话的流利程度打分，最终分数将根据流利程度在0分至题目设置的满分之间", style: commonStyles?.bodyStyle,));
        break;
      case EvalAudioQuestionBySimilarity:
        // scoreConditionName = "文本相似度（0-1之间）";
        settingFields.add(const SizedBox(height: 16,));
        settingFields.add(Text("该评分方式由系统自动根据患者所说内容和答案文本的相似度打分，最终分数将根据相似度在0分至题目设置的满分之间，如果开启模糊评分，当患者所说内容与答案文本相似度超过80%即为满分", style: commonStyles?.bodyStyle,));
        break;
      case EvalAudioQuestionByWordType:
        var rule = currQuestion.evalRule as EvalAudioQuestionByWordType;
        settingFields.add(const SizedBox(height: 16,));
        settingFields.add(Row(
          children: [
            Text("词性：", style: commonStyles?.bodyStyle,),
            DropdownMenu(
                width: 150,
                initialSelection: rule.wordType,
                requestFocusOnTap: false,
                enableSearch: false,
                onSelected: (int? value) {
                  rule.wordType = value ?? 1;
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 1, label: "动词"),
                  DropdownMenuEntry(value: 2, label: "名词"),
                ]),
          ],
        ));
        break;
      case EvalChoiceQuestionByCorrectChoiceCount:
        _buildChoiceQuestionRuleSetting(settingFields);
        break;
      case EvalCommandQuestionByCorrectActionCount:
        _buildCommandQuestionRuleSetting(settingFields);
        break;
      case EvalItemFoundQuestion:
        (currQuestion.evalRule as EvalItemFoundQuestion).imageUrl = currQuestion.imageUrl;
        _buildItemFoundQuestionRuleSetting(settingFields);
      default:
        break;
    }

    if (questionType != EvalAudioQuestionByFluency && questionType != EvalAudioQuestionBySimilarity) {
      _buildScoreConditionSetting(settingFields);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settingFields,
    );
  }

  void _buildChoiceQuestionRuleSetting(List<Widget> settingFields) {
    var rule = currQuestion.evalRule as EvalChoiceQuestionByCorrectChoiceCount;
    settingFields.add(Text("选项列表：", style: commonStyles?.bodyStyle,));
    settingFields.add(Container(
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
                if (rule.choices.length >= 20) {
                  toast(context, msg: "选项不可超过20个，当前已有${rule.choices.length}个选项。", btnText: "确认");
                } else {
                  showDialog<Choice?>(context: context, builder: (context) => const ChoiceSettingDialog()).then((choice) {
                    if (choice != null) {
                      setState(() {
                        rule.choices.add(choice);
                      });
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
              child: Text("新增选项", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                Text("正确选项列表：", style: commonStyles?.bodyStyle,),
                ...rule.correctChoices.asMap().entries.map((e) {
                  return Text('${e.key+1}. ${rule.choices[e.value].text}', style: commonStyles?.bodyStyle,);
                }).toList()
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 400,
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        // 标题行
                        return ListTile(
                          key: Key(index.toString()),
                          leading: SizedBox(
                            width: 82,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 66,
                                    child: Text("正确选项", style: commonStyles?.bodyStyle,)
                                ),
                                const Expanded(flex: 16, child: VerticalDivider()),
                              ],
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox.shrink(),
                              Text("操作", style: commonStyles?.bodyStyle,)
                            ],
                          ),
                        );
                      }

                      // 减去标题行一行
                      index--;
                      return ListTile(
                        key: Key((index+1).toString()),
                        leading: SizedBox(
                          width: 82,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 66,
                                child: Center(
                                  child: Checkbox(
                                      value: rule.correctChoices.contains(index),
                                      onChanged: (bool? value) {
                                        if (value ?? false) {
                                          setState(() {
                                            rule.correctChoices.add(index);
                                          });
                                        } else {
                                          setState(() {
                                            rule.correctChoices.remove(index);
                                          });
                                        }
                                      }
                                  ),
                                ),
                              ),
                              const Expanded(
                                  flex: 16,
                                  child: VerticalDivider()
                              ),
                            ],
                          ),
                        ),
                        title: buildListTileContentWithActionButtons(
                            body: Text("选项：${rule.choices[index].text}", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                            firstBtnTooltipMsg: "编辑",
                            firstBtnIcon: const Icon(Icons.edit),
                            firstBtnAction: () {
                              showDialog<Choice?>(context: context, builder: (context) => ChoiceSettingDialog(choice: rule.choices[index],)).then((choice) {
                                if (choice != null) {
                                  setState(() {
                                    rule.choices[index] = choice;
                                  });
                                }
                              });
                            },
                            secondBtnTooltipMsg: "删除",
                            secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles!.errorColor,),
                            secondBtnAction: () {
                              confirm(context, title: "确认", body: "确认要删除该选项吗？", commonStyles: commonStyles,
                                  onConfirm: (context) {
                                    // 关闭confirm dialog
                                    Navigator.pop(context);
                                    setState(() {
                                      rule.deleteChoice(index);
                                    });
                                  }
                              );
                            },
                            textAreaMaxHeight: listTileCommonHeight,
                            textAreaMaxWidth: max(constraints.maxWidth - 300, 0),
                            commonStyles: commonStyles,
                            moreButtons: [
                              createActionButtonSetting(
                                  btnTooltipMsg: "上移",
                                  btnIcon: const Icon(Icons.arrow_upward),
                                  btnAction: () {
                                    setState(() {
                                      rule.moveChoiceUp(index);
                                    });
                                  }
                              ),
                              createActionButtonSetting(
                                  btnTooltipMsg: "下移",
                                  btnIcon: const Icon(Icons.arrow_downward),
                                  btnAction: () {
                                    setState(() {
                                      rule.moveChoiceDown(index);
                                    });
                                  }
                              ),
                            ]
                        ),
                      );
                    },
                    itemCount: rule.choices.length + 1,
                  );
                }
            ),
          ),
        ],
      ),
    ));
  }

  void _buildCommandQuestionRuleSetting(List<Widget> settingFields) {
    final rule = currQuestion.evalRule as EvalCommandQuestionByCorrectActionCount;
    final invalidPunishmentInputSetting = ruleFieldsSetting["invalidActionPunishment"]!;

    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(
        Row(
          children: [
            Text("动作拆分模式：", style: commonStyles?.bodyStyle,),
            Checkbox(value: rule.detailMode, onChanged: (value) {
              setState(() {
                rule.detailMode = value ?? false;
              });
            }),
          ],
        )
    );
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(buildInputFormField("无效动作扣分值：", invalidPunishmentInputSetting['key'], invalidPunishmentInputSetting['ctrl'], invalidPunishmentInputSetting['validator'],
      commonStyles: commonStyles,
      width: 250,
    ));
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(Row(
      children: [
        Text("可操作区域数量：", style: commonStyles?.bodyStyle,),
        DropdownMenu(
          initialSelection: rule.slotCount,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 10, label: "10个"),
            DropdownMenuEntry(value: 20, label: "20个"),
          ],
          onSelected: (int? value) {
            setState(() {
              rule.slotCount = value ?? 10;
            });
          },
        ),
      ],
    ));
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(Text("操作区域设置：", style: commonStyles?.bodyStyle,));
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(_buildItemSlots(rule));
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(ElevatedButton(
        onPressed: () {
          if (rule.getSlotsWithItem().isEmpty) {
            toast(context, msg: "请至少在一个区域内设置一个物体后再进行正确操作录制。", btnText: "确认");
            return;
          }

          Navigator.push<List<CommandActions>?>(context, MaterialPageRoute(builder: (context) => CommandQuestionActionRecordPage(currRule : rule)))
              .then((actions) {
            if (actions != null) {
              assert(actions.isNotEmpty);
              setState(() {
                currQuestion.questionText = rule.updateActions(actions);
                generatedAudioUrl(currQuestion.questionText!).then((url) {
                  currQuestion.audioUrl = url;
                });
              });
            }
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
        child: Text("录制正确操作", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),))
    );
    settingFields.add(const SizedBox(height: 16,));
    settingFields.add(Text("正确操作指令：${rule.commandText ?? ""}",
      style: commonStyles?.bodyStyle,
    ));
  }

  Widget _buildItemSlots(EvalCommandQuestionByCorrectActionCount rule) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      shrinkWrap: true,
      children: rule.slots.asMap().entries.map((e) => Builder(
          builder: (context) {
            final index = e.key;
            final slot = e.value;
            showEditDialog() {
              showDialog<ItemSlot?>(context: context, builder: (context) => ItemSlotEditDialog(slot: slot, rule: rule, slotIndex: index)).then((slot) {
                if (slot != null) {
                  setState(() {
                    rule.setItemSlot(index, slot);
                  });
                }
              });
            }

            Widget content;
            if (slot.itemName != null) {
              content = Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: slot.itemImageUrl != null ? Image.network(slot.itemImageUrl!,
                          fit: BoxFit.contain,
                        ): Image.asset(slot.itemImageAssetPath!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text(slot.itemName!, style: commonStyles?.bodyStyle,)
                    ],
                  ),
                ),
              );
            } else {
              content = Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                      onPressed: showEditDialog,
                      icon: const Icon(Icons.add)
                  ),
                ),
              );
            }
            return InkWell(
              onTap: showEditDialog,
              child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: content
              ),
            );
          }
      )).toList()
    );
  }

  Widget _buildKeywordItem(int index, String keyword, KeywordList rule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(keyword, style: commonStyles?.bodyStyle,),
        SizedBox(
          width: 16.0,
          height: 16.0,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                rule.keywords.removeAt(index);
              });
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white,),
            style: IconButton.styleFrom(backgroundColor: Colors.grey),
            iconSize: 16.0,
          ),
        )
      ],
    );
  }

  void _buildItemFoundQuestionRuleSetting(List<Widget> settingFields) {
    settingFields.add(const SizedBox(height: 16,));

    // currQuestion.imageUrl = "https://img1.baidu.com/it/u=1671025097,439798995&fm=253&fmt=auto&app=138&f=JPEG?w=755&h=500";

    final rule = currQuestion.evalRule as EvalItemFoundQuestion;

    settingFields.add(Row(
      children: [
        Text("设置题干图片：", style: commonStyles?.bodyStyle,),
        ElevatedButton (
          onPressed: () {
            showDialog<Map<String, dynamic>?>(context: context, builder: (context) => SelectImagesDialog (
              imageUrl: !isImageUrlAssets(currQuestion.imageUrl) ? currQuestion.imageUrl : null,
              imageAssetPath: !isImageUrlAssets(currQuestion.imageUrl) ? null : currQuestion.imageUrl,
              commonStyles: commonStyles,
            )).then((map) {
              if(map != null) {
                setState(() {
                  currQuestion.imageUrl = map['imageUrl'] ?? map['imageAssetPath'];
                  rule.imageUrl = currQuestion.imageUrl;
                  currQuestion.omitImageAfterSeconds = -1;
                });
              }
            });
          },
          child: Text("设置", style: commonStyles?.bodyStyle,),
        ),
      ],
    ));
    settingFields.add(const SizedBox(height: 16,));
    if (currQuestion.imageUrl == null) {
      settingFields.add(Text("本规则要求患者在图片上作答，因此要求必须设置一张题干图片，检测到题干图片未设置，请点击上方按钮设置题干图片。", style: commonStyles?.bodyStyle,));
    } else {
      String? imageUrl;
      String? imageAssetPath;
      if (isImageUrlAssets(currQuestion.imageUrl)) {
        imageUrl = currQuestion.imageUrl;
      } else {
        imageAssetPath = currQuestion.imageUrl;
      }

      settingFields.add(buildImagePreview(imageUrl: imageUrl, imageAssetPath: imageAssetPath, commonStyles: commonStyles));
      settingFields.add(const SizedBox(height: 16,));
      settingFields.add(ElevatedButton(
        onPressed: () {
          Navigator.push<List<List<double>>?>(context, MaterialPageRoute(builder: (context) => ItemFindingQuestionAreaSettingPage(question: currQuestion as ItemFindingQuestion)))
            .then((coordinates) {
              if (coordinates != null) {
                setState(() {
                  rule.coordinates = coordinates;
                });
              }
          });
        },
        child: Text("设置点击区域", style: commonStyles?.bodyStyle,)
      ));
    }
  }

  void _buildScoreConditionSetting(List<Widget> settingFields) {
    final rule = currQuestion.evalRule!;
    settingFields.add(const Divider(height: 16,));
    settingFields.add(Text("得分条件列表：", style: commonStyles?.bodyStyle,));
    settingFields.add(Container(
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
                showDialog<EvalCondition?>(
                    context: context,
                    builder: (context) => QuestionScoreConditionEditDialog(scoreConditionName: rule.getScoreConditionName(), evalRule: rule, ))
                    .then((condition) {
                  if (condition != null) {
                    setState(() {
                      rule.addEvalCondition(condition);
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
              child: Text("新增得分条件", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
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
                      1: FlexColumnWidth(0.7),
                      2: FlexColumnWidth(1.3),
                      3: FlexColumnWidth(1.3),
                      4: FlexColumnWidth(1.0),
                      5: FlexColumnWidth(1.0),
                      6: FlexColumnWidth(0.7),
                      7: FlexColumnWidth(1.0),
                    },
                    children: [
                      TableRow(
                          children: [
                            Center(child: Text("序号", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("对应得分", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("${rule.getScoreConditionName()}下界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("${rule.getScoreConditionName()}上界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("作答时间下界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("作答时间上界", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("经过提示", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(child: Text("操作", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,))
                          ]
                      ),
                      ...rule.conditions.asMap().entries.map((e) {
                        final condIndex = e.key;
                        List<Map<String, dynamic>> ranges = e.value.ranges;

                        Widget timeLowBound = Text("/", style: commonStyles?.bodyStyle,);
                        Widget timeHighBound = Text("/", style: commonStyles?.bodyStyle,);
                        if (ranges.length > 1) {
                          timeLowBound = Text(e.value.ranges[1]['lowBound'].toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,);
                          timeHighBound = Text(e.value.ranges[1]['highBound'].toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,);
                        }

                        final buttonSize = commonStyles!.isMedium || commonStyles!.isLarge ? 30.0 : 20.0;

                        return TableRow(
                          children: [
                            Center(child: Text((e.key+1).toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Text(e.value.score.toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Text(e.value.ranges[0]['lowBound'].toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Text(e.value.ranges[0]['highBound'].toString(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: timeLowBound,
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: timeHighBound,
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Text(e.value.isHinted ? "是" : "否", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
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
                                      showDialog<EvalCondition?>(context: context,
                                          builder: (context) => QuestionScoreConditionEditDialog(condition: e.value, scoreConditionName: rule.getScoreConditionName(), evalRule: rule,))
                                          .then((condition) {
                                        if (condition != null) {
                                          setState(() {
                                            rule.updateEvalCondition(updated: condition, index: condIndex);
                                          });
                                        }
                                      });
                                    },
                                  ),
                                  createActionButtonSetting(btnTooltipMsg: "删除", btnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,size: buttonSize,),
                                    btnAction: () {
                                      confirm(context, title: "确认", body: "确认要删除该得分规则吗？", commonStyles: commonStyles,
                                        onConfirm: (context) {
                                          Navigator.pop(context);
                                          setState(() {
                                            rule.deleteEvalCondition(condIndex);
                                          });
                                        }
                                      );
                                    },
                                  ),
                                  createActionButtonSetting(btnTooltipMsg: "上移", btnIcon: Icon(Icons.arrow_upward, size: buttonSize,),
                                    btnAction: () {
                                      setState(() {
                                        rule.moveUpEvalCondition(condIndex);
                                      });
                                    },
                                  ),
                                  createActionButtonSetting(btnTooltipMsg: "下移", btnIcon: Icon(Icons.arrow_downward, size: buttonSize,),
                                    btnAction: () {
                                      setState(() {
                                        rule.moveDownEvalCondition(condIndex);
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
    ));
  }
}

class CommandQuestionActionRecordPage extends StatefulWidget {
  final EvalCommandQuestionByCorrectActionCount currRule;
  const CommandQuestionActionRecordPage({super.key, required this.currRule,});

  @override
  State<CommandQuestionActionRecordPage> createState() => _CommandQuestionActionRecordPageState();
}

class _CommandQuestionActionRecordPageState extends State<CommandQuestionActionRecordPage> with UseCommonStyles {
  late EvalCommandQuestionByCorrectActionCount currRule;
  late List<ItemSlot> currSlots;
  late List<StackableItemSlot> slots;
  late List<CommandActions> actions;
  late String commandText;
  CommandActions? currAction;

  void resetStates() {
    currRule = widget.currRule;
    currSlots = currRule.slots.map((e) => e.copy()).toList();
    slots = currSlots.map((e) => e.itemName == null? StackableItemSlot() : StackableItemSlot(e)).toList();
    actions = [];
    commandText = "";
  }

  @override
  void initState() {
    resetStates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (currRule != widget.currRule) {
      resetStates();
    }

    initStyles(context);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text("拖动物体进行操作录制", style: commonStyles?.titleStyle,)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemSlots(context, currRule),
                  const SizedBox(height: 16,),
                  Text("操作对应的指令文本：$commandText", style: commonStyles?.bodyStyle,),
                  const SizedBox(height: 16,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          confirm(context, title: "确认", body: "确定要重新录制吗？", commonStyles: commonStyles,
                            onConfirm: (context) {
                              Navigator.pop(context);
                              setState(() {
                                resetStates();
                              });
                            }
                          );
                        },
                        child: Text("重新录制", style: commonStyles?.bodyStyle,),
                      ),
                      const SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: () {
                          if (actions.isEmpty) {
                            toast(context, msg: "请至少记录一个动作再完成录制", btnText: "确认");
                            return;
                          }

                          if (currRule.actions.isNotEmpty) {
                            confirm(context, title: "确认", body: "当前规则已录制过正确操作，继续将覆盖已录制的操作，确认继续吗？", commonStyles: commonStyles,
                              onConfirm: (context) {
                                // 关闭确认弹窗
                                Navigator.pop(context);

                                // 从录制页返回到上一页
                                Navigator.pop(context, actions);
                              }
                            );
                          } else {
                            Navigator.pop(context, actions);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
                        child: Text("完成录制", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  Widget _buildItemSlots(BuildContext context, EvalCommandQuestionByCorrectActionCount rule) {
    final media = MediaQuery.of(context);
    final screenAspectRatio = media.size.aspectRatio;
    // debugPrint(screenAspectRatio.toString());
    const spacing = 2.0;

    return GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: screenAspectRatio,
        shrinkWrap: true,
        children: slots.asMap().entries.map((e) => Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Builder(
              builder: (context) {
                final index = e.key;
                final slot = e.value;

                Widget content;
                if (slot.items.isNotEmpty) {
                  content = LayoutBuilder(
                    builder: (context, constraints) {
                      return Draggable<StackableItemSlot>(
                        data: slot,
                        onDragStarted: () {
                          currAction = CommandActions(sourceSlotIndex: index, firstAction: ClickAction.take);
                        },
                        onDraggableCanceled: (v, offset) {
                          currAction = null;
                        },
                        feedback: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: _buildDragFeedback(slot),
                        ),
                        childWhenDragging: _buildSlotImagesWhenDragging(slot),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              actions.add(CommandActions(sourceSlotIndex: index, firstAction: ClickAction.touch));
                              commandText = rule.generateCommandTextFromActions(actions);
                            });
                          },
                          child: _buildSlotImages(slot)
                        ),
                      );
                    }
                  );
                } else {
                  content = const SizedBox.shrink();
                }
                return DragTarget(
                  builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
                    return content;
                  },
                  onAccept: (StackableItemSlot incomingSlot) {
                    assert(incomingSlot.items.isNotEmpty && currAction?.sourceSlotIndex != null);
                    final actionType = slot.items.isNotEmpty ? PutDownAction.putDown : PutDownAction.cover;

                    setState(() {
                      actions.add(currAction!..setSecondAction(index, actionType));
                      currAction = null;

                      commandText = rule.generateCommandTextFromActions(actions);
                      slot.pushItem(incomingSlot.popItem()!);
                    });
                  },
                );
              }
          ),
        )).toList()
    );
  }

  Widget _buildSlotImages(StackableItemSlot slot) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: slot.items.map((item) {
          return item.itemImageUrl != null ? Image.network(item.itemImageUrl!,
            fit: BoxFit.contain,
          ) : Image.asset(item.itemImageAssetPath!,
            fit: BoxFit.contain,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlotImagesWhenDragging(StackableItemSlot slot) {
    return Center(
      child: Stack(
        children: slot.items.asMap().entries.map((e) {
          var index = e.key;
          var item = e.value;

          if (index == slot.items.length - 1) {
            return const SizedBox.shrink();
          }

          return item.itemImageUrl != null ? Image.network(item.itemImageUrl!,
            fit: BoxFit.contain,
          ) : Image.asset(item.itemImageAssetPath!,
            fit: BoxFit.contain,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDragFeedback(StackableItemSlot slot) {
    assert(slot.items.isNotEmpty);
    final item = slot.items.last;

    return Center(
      child: item.itemImageUrl != null ? Image.network(item.itemImageUrl!,
        fit: BoxFit.contain,
      ) : Image.asset(item.itemImageAssetPath!,
        fit: BoxFit.contain,
      )
    );
  }
}

class ItemFindingQuestionAreaSettingPage extends StatefulWidget {
  final ItemFindingQuestion question;
  const ItemFindingQuestionAreaSettingPage({super.key, required this.question});

  @override
  State<ItemFindingQuestionAreaSettingPage> createState() => _ItemFindingQuestionAreaSettingPageState();
}

class _ItemFindingQuestionAreaSettingPageState extends State<ItemFindingQuestionAreaSettingPage> with UseCommonStyles {
  static const int maxPointCount = 20;
  late ItemFindingQuestion currQuestion;

  int pointCount = 0;

  late List<List<double>> coordinates;
  bool convexHullFinished = false;

  void resetState() {
    clearState();
    final rule = currQuestion.evalRule as EvalItemFoundQuestion;
    pointCount = rule.coordinates.isEmpty ? 0 : maxPointCount - rule.coordinates.length;

    coordinates = rule.coordinates.isEmpty ? [] : []..addAll(rule.coordinates);
  }

  void clearState() {
    currQuestion = widget.question;

    pointCount = 0;

    coordinates = [];
    convexHullFinished = false;
  }

  void addCoordinate(double px, double py, double maxX, double maxY) {
    if (pointCount == maxPointCount) {
      toast(context, msg: "至多指定20个顶点，当前顶点数量已达上限。", btnText: "确认");
      return;
    }

    coordinates.add(normalizePosition(px, py, maxX, maxY));
    pointCount++;
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  Future<ui.Image> getImageFromProvider(ImageProvider imageProvider) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) async {
        ByteData? byteData = await info.image.toByteData();
        Uint8List? uint8List = byteData?.buffer.asUint8List();
        ui.Codec codec = await ui.instantiateImageCodec(uint8List!);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        completer.complete(frameInfo.image);
      }),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    final imageCompleter = Completer<ui.Image>();
    Image questionImage;
    if (isImageUrlAssets(currQuestion.imageUrl)) {
      questionImage = Image(image: AssetImage(currQuestion.imageUrl!), fit: BoxFit.contain,);
    } else {
      questionImage = Image(
        image: NetworkImage(currQuestion.imageUrl!),
        fit: BoxFit.contain,
      );
    }

    questionImage.image.resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, _) {
      imageCompleter.complete(imageInfo.image);
    }));

    if (currQuestion != widget.question) {
      resetState();
    }


    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text("场景寻物题点击区域设置", style: commonStyles?.titleStyle,)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("仅支持设置凸多边形区域，请在图片上点击设置多边形区域的顶点（至多20个顶点），设置完毕后点击“完成”按钮以生成区域，系统会自动根据设置的顶点求出一个最大的凸多边形区域，区域生成后点击“确认设置”按钮保存并返回到规则设置页面", style: commonStyles?.bodyStyle,),
                Text("顶点数：$pointCount/$maxPointCount", style: commonStyles?.bodyStyle,),
                const Divider(height: 32,),
                FutureBuilder<ui.Image>(
                  future: imageCompleter.future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      toast(context, msg: "图片加载失败，请重试。", btnText: "确认");
                      return Center(
                        child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                      );
                    } else if (!snapshot.hasData) {
                      return Center(
                        child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                      );
                    }

                    final image = snapshot.data!;
                    final mediaSize = MediaQuery.of(context).size;
                    double maxWidth = mediaSize.width * 0.7;
                    double maxHeight = mediaSize.height * 0.7;
                    double boxWidth;
                    double boxHeight;
                    if (image.height * (maxWidth / image.width) <= maxHeight) {
                      boxWidth = maxWidth;
                      boxHeight = image.height * (maxWidth / image.width);
                    } else {
                      boxWidth = image.width * (maxHeight / image.height);
                      boxHeight = maxHeight;
                    }

                    return Container(
                      width: boxWidth,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0)
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTapDown: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              // find the coordinate
                              final Offset localOffset = box.globalToLocal(details.globalPosition);
                              final posX = localOffset.dx;
                              final posY = localOffset.dy;
                              setState(() {
                                addCoordinate(posX, posY, boxWidth, boxHeight);
                              });
                            },
                            child: questionImage
                          ),
                          ...coordinates.map((e) => Positioned(
                              left: e.first * boxWidth - 9,
                              top: e.last * boxHeight - 9,
                              width: 18,
                              height: 18,
                              // child: Text("${(e.first * 1000).roundToDouble() / 1000};${(e.last * 1000).roundToDouble() / 1000}",)
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.circle_rounded, color: Colors.green, size: 12.0,)
                                ),
                              ),
                          )).toList(),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 32,),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            clearState();
                          });
                        },
                        child: Text("重设", style: commonStyles?.bodyStyle,)
                      ),
                      const SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (coordinates.length < 3) {
                              toast(context, msg: "请至少设置3个顶点，至少3个顶点才能形成一个封闭区域", btnText: "确认");
                              return;
                            }
                            coordinates = convexHull(coordinates);
                            // debugPrint(coordinates.toString());
                            convexHullFinished = true;
                          });
                        },
                        child: Text("完成", style: commonStyles?.bodyStyle,)
                      ),
                      const SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: () {
                          if (convexHullFinished) {
                            Navigator.pop(context, coordinates);
                          } else {
                            toast(context, msg: "请先点击“完成”按钮生成区域再确认设置", btnText: "确认");
                          }
                        },
                        child: Text("确认设置", style: commonStyles?.bodyStyle,)
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ),
    );
  }
}