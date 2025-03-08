import 'package:flutter/material.dart';

import '../../../enum/command_actions.dart';
import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../models/result/results.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';


class StackableItemSlot {
  List<ItemSlot> items = [];

  bool _checkSlot(ItemSlot slot) {
    return slot.itemName != null &&
        (slot.itemImageAssetPath != null || slot.itemImageUrl != null);
  }

  StackableItemSlot([ItemSlot? slot]) {
    if (slot != null) {
      if (_checkSlot(slot)) {
        items.add(slot);
      } else {
        throw ArgumentError("slot中必须设置item");
      }
    }
  }

  void pushItem(ItemSlot slot) {
    _checkSlot(slot);
    items.add(slot);
  }

  ItemSlot? popItem() {
    return items.isEmpty ? null : items.removeLast();
  }

  ItemSlot? peekItem() {
    return items.isEmpty ? null : items.last;
  }
}

class CommandQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const CommandQuestionAnswerArea(
      {super.key,
        required this.question,
        required this.commonStyles,
        required this.goToNextQuestion});

  @override
  State<CommandQuestionAnswerArea> createState() =>
      _CommandQuestionAnswerAreaState();
}

class _CommandQuestionAnswerAreaState extends State<CommandQuestionAnswerArea>
    with QuestionAnswerArea
    implements ResettableState {

  // 常规变量
  late CommandQuestion currQuestion;
  late CommandQuestionResult result;

  late List<StackableItemSlot> slots;
  List<CommandActions> actionsDone = [];
  CommandActions? currAction;

  bool answerStart = false;

  @override
  void resetState() {
    currQuestion = widget.question as CommandQuestion;
    EvalCommandQuestionByCorrectActionCount rule = currQuestion.evalRule as EvalCommandQuestionByCorrectActionCount;
    result = CommandQuestionResult(sourceQuestion: widget.question);
    slots = rule.slots.map((e) => e.itemName == null? StackableItemSlot() : StackableItemSlot(e)).toList();
    actionsDone = [];
    answerStart = false;

    initQuestionStem(currQuestion);
  }

  @override
  void finishAnswer() {
    doCommonFinishStep(result);

    debugPrint("actionsDone: ${actionsDone.map((e) => e.toJson())}");
    evalQuestion(actionsDone: actionsDone, result: result, question: currQuestion);
  }

  void evalQuestion({required List<CommandActions> actionsDone, required CommandQuestion question, required CommandQuestionResult result}) {
    result.actions = actionsDone;

    doEvalQuestion(question: question, result: result, goToNextQuestion: widget.goToNextQuestion);
  }

  @override
  void resetAnswerStateAfterHint(QuestionEvalRule rule) {
    EvalCommandQuestionByCorrectActionCount r = rule as EvalCommandQuestionByCorrectActionCount;
    slots = r.slots.map((e) => e.itemName == null? StackableItemSlot() : StackableItemSlot(e)).toList();
    actionsDone = [];
    currAction = null;
  }

  @override
  void initState() {
    super.initState();

    resetState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    disposePlayerAndCounters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currQuestion != widget.question) {
      // 题目切换
      resetState();
    }

    final commonStyles = widget.commonStyles;

    if (evaluating) {
      return Center(
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
              child: Text('评分中，请稍候', style: commonStyles!.hintTextStyle,),
            ),
          ],
        ),
      );
    }

    List<Widget> questionBoard = [];
    if (isQuestionTextDisplayed) {
      questionBoard.add(Expanded(
          flex: 1,
          child: Center(
            child: Text(
              displayText ?? "不应该为这个",
              style: commonStyles?.titleStyle,
            ),
          )));
    }

    if (imageDisplayed) {
      questionBoard.add(Expanded(
        flex: 6,
        child: buildUrlOrAssetsImage(
          context,
          imageUrl: displayImageUrl!,
          commonStyles: commonStyles,
        ),
      ));
    } else {
      questionBoard.add(Expanded(
        flex: 6,
        child: _buildItemSlots(context, commonStyles: commonStyles, question: currQuestion),
      ));
    }

    Widget actionArea = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () {
              finishAnswer();
            },
            child: Text(
              "好了",
              style: commonStyles?.bodyStyle,
            )),
        const SizedBox(
          height: 16,
        ),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );

    Widget contentArea;
    if (questionBoard.isEmpty) {
      contentArea = Center(
        child: actionArea,
      );
    } else {
      contentArea = Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: questionBoard,
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(flex: 1, child: actionArea),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: contentArea,
    );
  }

  Widget _buildItemSlots(BuildContext context, {required Question question, CommonStyles? commonStyles}) {
    EvalCommandQuestionByCorrectActionCount evalRule = question.evalRule! as EvalCommandQuestionByCorrectActionCount;

    final media = MediaQuery.of(context);
    var aGoodAspectRatio = media.size.aspectRatio;

    return GridView.count(
      mainAxisSpacing: 4.0,
      crossAxisCount: 5,
      crossAxisSpacing: 4.0,
      childAspectRatio: aGoodAspectRatio,
      shrinkWrap: true,
      children: slots.asMap().entries.map((e) {
        final index = e.key;
        final slot = e.value;

        return Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Builder(
            builder: (context) {
              Widget content;
              if (slot.items.isNotEmpty) {
                content = LayoutBuilder(
                    builder: (context, constraints) {
                      return Draggable<StackableItemSlot>(
                        data: slot,
                        onDragStarted: () {
                          if (answerStart = false) {
                            trySetAnswerTime(result, timeLimitCountDown!.timePassed);
                            debugPrint("answer started at: ${timeLimitCountDown!.timePassed}");
                            answerStart = true;
                          }
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
                                if (answerStart = false) {
                                  trySetAnswerTime(result, timeLimitCountDown!.timePassed);
                                  debugPrint("answer started at: ${timeLimitCountDown!.timePassed}");
                                  answerStart = true;
                                }
                                actionsDone.add(CommandActions(sourceSlotIndex: index, firstAction: ClickAction.touch));
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
                    actionsDone.add(currAction!..setSecondAction(index, actionType));
                    currAction = null;

                    slot.pushItem(incomingSlot.popItem()!);
                  });
                },
              );
            }
          ),
        );
      }).toList(),
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
