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

  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const _dragElevation = 8.0;

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
    EvalCommandQuestionByCorrectActionCount rule =
        currQuestion.evalRule as EvalCommandQuestionByCorrectActionCount;
    result = CommandQuestionResult(sourceQuestion: widget.question);
    slots = rule.slots
        .map((e) =>
            e.itemName == null ? StackableItemSlot() : StackableItemSlot(e))
        .toList();
    actionsDone = [];
    answerStart = false;

    initQuestionStem(currQuestion);
  }

  @override
  void finishAnswer() {
    doCommonFinishStep(result);

    debugPrint("actionsDone: ${actionsDone.map((e) => e.toJson())}");
    evalQuestion(
        actionsDone: actionsDone, result: result, question: currQuestion);
  }

  void evalQuestion(
      {required List<CommandActions> actionsDone,
      required CommandQuestion question,
      required CommandQuestionResult result}) {
    result.actions = actionsDone;

    doEvalQuestion(
        question: question,
        result: result,
        goToNextQuestion: widget.goToNextQuestion);
  }

  @override
  void resetAnswerStateAfterHint(QuestionEvalRule rule) {
    EvalCommandQuestionByCorrectActionCount r =
        rule as EvalCommandQuestionByCorrectActionCount;
    slots = r.slots
        .map((e) =>
            e.itemName == null ? StackableItemSlot() : StackableItemSlot(e))
        .toList();
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('评分中，请稍候', style: commonStyles?.hintTextStyle),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.commonStyles?.primaryColor?.withOpacity(0.03) ?? Colors.white,
                widget.commonStyles?.onPrimaryColor?.withOpacity(0.05) ?? Colors.white,
              ]
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContentArea(widget.commonStyles),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(CommonStyles? commonStyles) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildQuestionBoard(commonStyles),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildActionArea(commonStyles),
        )
      ],
    );
  }

  Widget _buildQuestionBoard(CommonStyles? commonStyles) {
    if (imageDisplayed) {
      return buildUrlOrAssetsImage(
        context,
        imageUrl: displayImageUrl!,
        commonStyles: commonStyles,
      );
    }
    return _buildItemSlots(context, commonStyles: commonStyles, question: currQuestion);
  }

   Widget _buildActionArea(CommonStyles? commonStyles) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: Text("提交操作",
            style: commonStyles?.bodyStyle?.copyWith(
              color: Colors.white,
              fontSize: 16
            )
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: commonStyles?.primaryColor ?? Colors.blueAccent,
            padding: _buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
          ),
          onPressed: finishAnswer,
        ),
        const SizedBox(height: 24),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );
  }

  Widget _buildItemSlots(BuildContext context,
      {required Question question, CommonStyles? commonStyles}) {
    // EvalCommandQuestionByCorrectActionCount evalRule =
    //     question.evalRule! as EvalCommandQuestionByCorrectActionCount;

    // final media = MediaQuery.of(context);
    // var aGoodAspectRatio = media.size.aspectRatio;

    // return GridView.count(
    //   mainAxisSpacing: 4.0,
    //   crossAxisCount: 5,
    //   crossAxisSpacing: 4.0,
    //   childAspectRatio: aGoodAspectRatio,
    //   shrinkWrap: true,
    //   children: slots.asMap().entries.map((e) {
    //     final index = e.key;
    //     final slot = e.value;

    //     return Container(
    //       decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
    //       child: Builder(builder: (context) {
    //         Widget content;
    //         if (slot.items.isNotEmpty) {
    //           content = LayoutBuilder(builder: (context, constraints) {
    //             return Draggable<StackableItemSlot>(
    //               data: slot,
    //               onDragStarted: () {
    //                 if (answerStart = false) {
    //                   trySetAnswerTime(result, timeLimitCountDown!.timePassed);
    //                   debugPrint(
    //                       "answer started at: ${timeLimitCountDown!.timePassed}");
    //                   answerStart = true;
    //                 }
    //                 currAction = CommandActions(
    //                     sourceSlotIndex: index, firstAction: ClickAction.take);
    //               },
    //               onDraggableCanceled: (v, offset) {
    //                 currAction = null;
    //               },
    //               feedback: SizedBox(
    //                 width: constraints.maxWidth,
    //                 height: constraints.maxHeight,
    //                 child: _buildDragFeedback(slot),
    //               ),
    //               childWhenDragging: _buildSlotImagesWhenDragging(slot),
    //               child: InkWell(
    //                   onTap: () {
    //                     setState(() {
    //                       if (answerStart = false) {
    //                         trySetAnswerTime(
    //                             result, timeLimitCountDown!.timePassed);
    //                         debugPrint(
    //                             "answer started at: ${timeLimitCountDown!.timePassed}");
    //                         answerStart = true;
    //                       }
    //                       actionsDone.add(CommandActions(
    //                           sourceSlotIndex: index,
    //                           firstAction: ClickAction.touch));
    //                     });
    //                   },
    //                   child: _buildSlotImages(slot)),
    //             );
    //           });
    //         } else {
    //           content = const SizedBox.shrink();
    //         }
    //         return DragTarget(
    //           builder: (BuildContext context, List<Object?> candidateData,
    //               List<dynamic> rejectedData) {
    //             return content;
    //           },
    //           onAcceptWithDetails: (DragTargetDetails<Object?> details) {
    //             final incomingSlot = details.data as StackableItemSlot;
    //             assert(incomingSlot.items.isNotEmpty && currAction?.sourceSlotIndex != null);
    //             final actionType = slot.items.isNotEmpty
    //                 ? PutDownAction.putDown
    //                 : PutDownAction.cover;

    //             setState(() {
    //               actionsDone.add(currAction!..setSecondAction(index, actionType));
    //               currAction = null;

    //               slot.pushItem(incomingSlot.popItem()!);
    //             });
    //           },
    //         );
    //       }),
    //     );
    //   }).toList(),
    // );
     return GridView.count(
      mainAxisSpacing: 8.0,
      crossAxisCount: 5,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      children: slots.asMap().entries.map((e) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(2, 2)
              )
            ]
          ),
          child: _buildDraggableSlot(e.key, e.value, commonStyles),
        );
      }).toList(),
    );
  }

  Widget _buildDraggableSlot(int index, StackableItemSlot slot, CommonStyles? commonStyles) {
    return DragTarget<StackableItemSlot>(
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
              ? commonStyles?.primaryColor?.withOpacity(0.1)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(12)
          ),
          child: _buildSlotContent(index, slot, commonStyles),
        );
      },
      onAcceptWithDetails: (details) {
        final incomingSlot = details.data as StackableItemSlot;
        assert(incomingSlot.items.isNotEmpty && currAction?.sourceSlotIndex != null);
        final actionType = slot.items.isNotEmpty
            ? PutDownAction.putDown
            : PutDownAction.cover;

        setState(() {
          actionsDone.add(currAction!..setSecondAction(index, actionType));
          currAction = null;

          slot.pushItem(incomingSlot.popItem()!);
        });
      },
    );
  }

  Widget _buildSlotContent(int index, StackableItemSlot slot, CommonStyles? commonStyles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Draggable<StackableItemSlot>(
          data: slot,
          onDragStarted: () {
            if (answerStart = false) {
              trySetAnswerTime(result, timeLimitCountDown!.timePassed);
              debugPrint(
                  "answer started at: ${timeLimitCountDown!.timePassed}");
              answerStart = true;
            }
            currAction = CommandActions(
                sourceSlotIndex: index, firstAction: ClickAction.take);
          },
          onDraggableCanceled: (v, offset) {
            currAction = null;
          },
          childWhenDragging: _buildSlotImagesWhenDragging(slot),
          feedback: Opacity(
            opacity: 0.7,
            child: Material(
              elevation: _dragElevation,
              borderRadius: BorderRadius.circular(12),
              child: _buildDragFeedback(slot),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (!answerStart) {
                  trySetAnswerTime(result, timeLimitCountDown!.timePassed);
                  debugPrint("answer started at: ${timeLimitCountDown!.timePassed}");
                  answerStart = true;
                }
                // 添加点击操作记录
                actionsDone.add(CommandActions(
                    sourceSlotIndex: index,
                    firstAction: ClickAction.touch));
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.9)
              ),
              child: _buildSlotImages(slot),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSlotImages(StackableItemSlot slot) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: slot.items.map((item) {
          return item.itemImageUrl != null
              ? Image.network(
                  item.itemImageUrl!,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  item.itemImageAssetPath!,
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

          return item.itemImageUrl != null
              ? Image.network(
                  item.itemImageUrl!,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  item.itemImageAssetPath!,
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
      child: item.itemImageUrl != null
          ? Image.network(
              item.itemImageUrl!,
              fit: BoxFit.contain,
            )
          : Image.asset(
              item.itemImageAssetPath!,
              fit: BoxFit.contain,
            ));
  }
}
