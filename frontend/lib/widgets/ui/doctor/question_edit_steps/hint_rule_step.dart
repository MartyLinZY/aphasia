import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';

import '../doctor_hint_rule_edit_dialog.dart';

class HintRuleStep extends StatefulWidget {
  final Question currQuestion;
  final bool requesting;
  final CommonStyles commonStyles;
  final double listTileCommonHeight;
  final double cardElevation;

  const HintRuleStep({
    super.key,
    required this.currQuestion,
    required this.requesting,
    required this.commonStyles,
    required this.listTileCommonHeight,
    required this.cardElevation,
  });

  @override
  State<HintRuleStep> createState() => _HintRuleStepState();
}

class _HintRuleStepState extends State<HintRuleStep> {
  @override
  Widget build(BuildContext context) {
    final commonStyles = widget.commonStyles;
    final currQuestion = widget.currQuestion;

    if (widget.requesting) {
      return wrappedByCard(
        elevation: widget.cardElevation,
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
                child: Text('处理中，请稍候', style: commonStyles.hintTextStyle),
              ),
            ],
          ),
        ),
      );
    }

    return wrappedByCard(
      elevation: widget.cardElevation,
      child: Column(
        children: [
          Text("提示规则", style: commonStyles.titleStyle),
          const Divider(),
          Text("提示条件列表（每道题只会触发一条提示）：", style: commonStyles.bodyStyle),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
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
                    style: ElevatedButton.styleFrom(backgroundColor: commonStyles.primaryColor),
                    child: Text("新增提示条件",
                        style: commonStyles.bodyStyle?.copyWith(color: commonStyles.onPrimaryColor)),
                  ),
                ),
                const Divider(),
                SizedBox(
                  height: 400,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return Table(
                        border: TableBorder.all(),
                        columnWidths: const <int, TableColumnWidth>{
                          0: FlexColumnWidth(0.5),
                          4: FlexColumnWidth(1.5),
                          5: FlexColumnWidth(1.5),
                          6: FlexColumnWidth(1.0),
                        },
                        children: [
                          TableRow(children: [
                            Center(child: Text("序号", style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis)),
                            Center(child: Text("触发提示得分下界", style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis)),
                            Center(child: Text("触发提示得分上界", style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis)),
                            Center(child: Text("操作", style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis)),
                          ]),
                          ...currQuestion.evalRule!.hintRules.asMap().entries.map((e) {
                            final hintIndex = e.key;
                            HintRule hintRule = e.value;

                            final buttonSize = commonStyles.isMedium || commonStyles.isLarge ? 30.0 : 20.0;

                            return TableRow(
                              children: [
                                Center(child: Text((e.key + 1).toString(), style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis)),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                    child: Text(hintRule.scoreLowBound.toString(),
                                        style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                    child: Text(hintRule.scoreHighBound.toString(),
                                        style: commonStyles.bodyStyle, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                Center(
                                  child: buildListTileContentWithActionButtons(
                                    body: const SizedBox.shrink(),
                                    textAreaMaxHeight: widget.listTileCommonHeight,
                                    textAreaMaxWidth: 0,
                                    mainAxisSize: MainAxisSize.min,
                                    buttonSize: buttonSize,
                                    commonStyles: commonStyles,
                                    moreButtons: [
                                      createActionButtonSetting(
                                        btnTooltipMsg: "编辑",
                                        btnIcon: Icon(Icons.edit, size: buttonSize),
                                        btnAction: () {
                                          showDialog<HintRule?>(
                                              context: context,
                                              builder: (context) => HintRuleEditDialog(
                                                  question: currQuestion, hintRule: hintRule))
                                              .then((updated) {
                                            if (updated != null) {
                                              setState(() {
                                                currQuestion.evalRule!
                                                    .updateHintRule(updated: updated, index: hintIndex);
                                              });
                                            }
                                          });
                                        },
                                      ),
                                      createActionButtonSetting(
                                        btnTooltipMsg: "删除",
                                        btnIcon: Icon(Icons.delete_outline, color: commonStyles.errorColor, size: buttonSize),
                                        btnAction: () {
                                          confirm(context,
                                              title: "确认",
                                              body: "确认要删除该提示规则吗？",
                                              commonStyles: commonStyles, onConfirm: (context) {
                                            Navigator.pop(context);
                                            setState(() {
                                              currQuestion.evalRule!.deleteHintRule(hintIndex);
                                            });
                                          });
                                        },
                                      ),
                                      createActionButtonSetting(
                                        btnTooltipMsg: "上移",
                                        btnIcon: Icon(Icons.arrow_upward, size: buttonSize),
                                        btnAction: () {
                                          setState(() {
                                            currQuestion.evalRule!.moveUpHintRule(hintIndex);
                                          });
                                        },
                                      ),
                                      createActionButtonSetting(
                                        btnTooltipMsg: "下移",
                                        btnIcon: Icon(Icons.arrow_downward, size: buttonSize),
                                        btnAction: () {
                                          setState(() {
                                            currQuestion.evalRule!.moveDownHintRule(hintIndex);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
