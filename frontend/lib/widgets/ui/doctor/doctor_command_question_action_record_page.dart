import 'package:aphasia_recovery/enum/command_actions.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:flutter/material.dart';

import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../do_exam/command_question.dart';

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
                return DragTarget<StackableItemSlot>(
                  builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
                    return content;
                  },
                  onAcceptWithDetails: (DragTargetDetails<StackableItemSlot> details) {
                    final incomingSlot = details.data;
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
