import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/question/question.dart';
import '../../utils/common_widget_function.dart';

class AnswerResultPage extends StatefulWidget {
  final CommonStyles? commonStyles;
  final ExamResult examResult;
  const AnswerResultPage({super.key, required this.commonStyles, required this.examResult});

  @override
  State<AnswerResultPage> createState() => _AnswerResultPageState();
}

class _AnswerResultPageState extends State<AnswerResultPage> with UseCommonStyles {
  final double viewingIconWidth = 36.0;
  final double expandIconWidth = 36.0;
  final double listTilePaddingBase = 8.0;
  double _menuWidth = 240.0;

  dynamic viewingItem;
  int? categoryIndex;
  int? subCategoryIndex;
  int? questionIndex;

  double getTileWidth({required double leftPadding, required bool hasExpandIcon, required bool hasViewingIcon}) {
    return max(0, _menuWidth - leftPadding - 20 - (hasExpandIcon ? expandIconWidth : 0) - (hasViewingIcon ? viewingIconWidth : 0));
  }

  @override
  void initState() {
    super.initState();
    viewingItem = widget.examResult;
  }


  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    final examResult = widget.examResult;

    double minMenuWidth = 10 * listTilePaddingBase + expandIconWidth;

    return Scaffold(
      appBar: AppBar(title: Text("查看测评结果", style: commonStyles?.titleStyle,),),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return wrappedByCard (
                    elevation: 8.0,
                    child: Row(
                      children: [
                        GestureDetector(
                          onHorizontalDragUpdate: (detail) {
                            setState(() {
                              _menuWidth = max(minMenuWidth, min(600, _menuWidth + detail.primaryDelta!));
                            });
                          },
                          child: SizedBox(
                            width: _menuWidth,
                            height: constraints.maxHeight,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const Divider(),
                                  _buildSummaryTile(examResult),
                                  const Divider(),
                                  Text("测评结果详情", style: commonStyles?.bodyStyle,),
                                  _buildQuestionTile(context, examResult),
                                  const Divider(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: _buildResultArea(context),
                        )
                      ],
                    ),
                  );
                }
            ),
          ),
      ),
    );
  }


  Widget _buildSummaryTile(ExamResult result) {
    bool viewingSummary = viewingItem.runtimeType == ExamResult;

    double tilePadding = listTilePaddingBase + expandIconWidth;
    return ListTile(
      onTap: () {
        setState(() {
          viewingItem = result;
        });
      },
      title: buildListTileContentWithActionButtons(
          body: Text("测评整体结果", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
          textAreaMaxHeight: commonStyles!.listTileCommonHeight,
          textAreaMaxWidth: max(_menuWidth - tilePadding - (viewingSummary? viewingIconWidth : 0), 0), // 如果正在查看，再减去”查看中“Icon的宽度
          commonStyles: commonStyles,
          moreButtons: ! viewingSummary? null: [createActionButtonSetting(
            btnTooltipMsg: "查看中",
            btnIcon: Icon(Icons.remove_red_eye, color: commonStyles?.primaryColor,),
            btnAction: null,
          )]
      ),
      contentPadding: EdgeInsets.only(left: tilePadding),
    );
  }

  Widget _buildQuestionTile(BuildContext context, ExamResult result) {
    var categoryWidgets = <Widget>[];
    for (int i = 0;i < result.categoryResults.length;i++) {
      var categoryRes = result.categoryResults[i];
      var subCategoryWidgets = <Widget>[];
      for (int j = 0;j < categoryRes.subResults.length;j++) {
        var subRes = categoryRes.subResults[j];
        var questionWidgets = <Widget>[];
        for (int k = 0;k < subRes.questionResults.length;k++) {
          var qRes = subRes.questionResults[k];
          var q = qRes.sourceQuestion;

          double tilePadding = 3 * listTilePaddingBase + expandIconWidth;
          bool viewingCurrentTile = categoryIndex == i && subCategoryIndex == j && questionIndex == k && viewingItem is QuestionResult;

          // debugPrint("查看$categoryIndex;$subCategoryIndex;$questionIndex，当前$i;$j;$k");
          questionWidgets.add(ListTile(
            onTap: () {
              setState(() {
                viewingItem = qRes;
                categoryIndex = i;
                subCategoryIndex = j;
                questionIndex = k;
              });
            },

            contentPadding: EdgeInsets.only(left: tilePadding),
            title: buildListTileContentWithActionButtons(
                body: Text(q.alias ?? q.defaultQuestionName(), style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                textAreaMaxHeight: commonStyles!.listTileCommonHeight,
                textAreaMaxWidth: getTileWidth(leftPadding: tilePadding, hasExpandIcon: false, hasViewingIcon: viewingCurrentTile),
                commonStyles: commonStyles,
                moreButtons: !viewingCurrentTile ? null: [createActionButtonSetting(
                  btnTooltipMsg: "查看中",
                  btnIcon: Icon(Icons.remove_red_eye, color: commonStyles?.primaryColor,),
                  btnAction: null,
                )]
            ),
          ));
        }

        double tilePadding = 3 * listTilePaddingBase;
        bool viewingCurrentTile = categoryIndex == i && subCategoryIndex == j && viewingItem.runtimeType == SubCategoryResult;
        subCategoryWidgets.add(ExpansionTile(
          backgroundColor: commonStyles!.theme.focusColor.withAlpha(40),
          tilePadding: EdgeInsets.only(left: tilePadding),
          controlAffinity: ListTileControlAffinity.leading,
          title: InkWell(
            onTap: () {
              setState(() {
                viewingItem = subRes;
                categoryIndex = i;
                subCategoryIndex = j;
              });
            },
            child: buildListTileContentWithActionButtons(
                body: Text(subRes.name ?? "第${j+1}子项", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
                textAreaMaxHeight: commonStyles!.listTileCommonHeight,
                textAreaMaxWidth: getTileWidth(leftPadding: tilePadding, hasExpandIcon: true, hasViewingIcon: viewingCurrentTile),
                commonStyles: commonStyles,
                moreButtons: !viewingCurrentTile ? null: [createActionButtonSetting(
                  btnTooltipMsg: "查看中",
                  btnIcon: Icon(Icons.remove_red_eye, color: commonStyles?.primaryColor,),
                  btnAction: null,
                )]
            ),
          ),
          children: questionWidgets,
        ));
      }

      categoryWidgets.add(Builder(
          builder: (context) {
            bool viewingCurrentTile = categoryIndex == i && viewingItem.runtimeType == CategoryResult;

            double tilePadding = listTilePaddingBase;
            return ExpansionTile(
              backgroundColor: commonStyles?.theme.focusColor,
              key: Key("category$i"),
              tilePadding: EdgeInsets.only(left: tilePadding),
              controlAffinity: ListTileControlAffinity.leading,
              title: InkWell(
                onTap: () {
                  setState(() {
                    viewingItem = categoryRes;
                    categoryIndex = i;
                  });
                },
                child: buildListTileContentWithActionButtons(
                  body: Text(categoryRes.name ?? "第${i+1}亚项", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis),
                  textAreaMaxHeight: commonStyles!.listTileCommonHeight,
                  textAreaMaxWidth: getTileWidth(leftPadding: tilePadding, hasExpandIcon: true, hasViewingIcon: viewingCurrentTile),
                  commonStyles: commonStyles,
                  moreButtons: !viewingCurrentTile ? null: [createActionButtonSetting(
                    btnTooltipMsg: "查看中",
                    btnIcon: Icon(Icons.remove_red_eye, color: commonStyles?.primaryColor,),
                    btnAction: null,
                  )]
                ),
              ),
              children: [
                // _buildCategoryRuleTile(),
                ...subCategoryWidgets,
              ],
            );
          }
      )
      );
    }

    categoryWidgets = categoryWidgets.isEmpty ? [Text("无", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)] : categoryWidgets;

    return Column(
      children: categoryWidgets.isEmpty ?
      [Text("无数据，请退出重试", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,)] : categoryWidgets,
    );
  }

  Widget _buildResultArea(BuildContext context) {
    Widget child;

    if (viewingItem == null) {
      child = const SizedBox.shrink();
    } else if (viewingItem.runtimeType == ExamResult) {
      child = _buildExamResultArea(context, viewingItem);
    } else if (viewingItem.runtimeType == CategoryResult) {
      child = _buildCateResArea(context, viewingItem);
    } else if (viewingItem.runtimeType == SubCategoryResult) {
      child = _buildSubCateResArea(context, viewingItem);
    } else if (viewingItem is QuestionResult) {
      child = _buildQuestionResArea(context, viewingItem);
    } else {
      throw UnimplementedError("unexpected viewingItem");
    }

    return SizedBox.expand(
      child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.blueGrey),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 16.0,
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    var minHeight = 400.0;
                    var minWidth = 600.0;

                    var horizontalScrollCtrl = ScrollController();
                    var verticalScrollCtrl = ScrollController();
                    return Scrollbar(
                      controller: horizontalScrollCtrl,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: horizontalScrollCtrl,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: minWidth,
                              minHeight: minHeight,
                              maxWidth: constraints.maxWidth < minWidth? minWidth : constraints.maxWidth
                          ),
                          child: Scrollbar(
                            controller: verticalScrollCtrl,
                            child: SingleChildScrollView(
                              controller: verticalScrollCtrl,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: minWidth,
                                    minHeight: minHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
              ),
            ),
          )
      ),
    );
  }

  Widget _buildExamResultArea(BuildContext context, ExamResult result) {
    DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("测评整体结果", style: commonStyles?.titleStyle,),
        const Divider( ),
        Row(
          children: [
            Text("诊断结果：", style: commonStyles?.bodyStyle,),
            Text(result.resultText ?? "", style: commonStyles?.bodyStyle?.copyWith(fontWeight: FontWeight.bold),),
          ],
        ),
        const SizedBox(height: 16,),
        result.finalScore == null
            ? const SizedBox.shrink()
            : Text("测评总分：${result.finalScore}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("开始作答时间：${format.format(result.startTime!)}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("结束作答时间：${result.finishTime == null ? "": format.format(result.finishTime!)}", style: commonStyles?.bodyStyle,),
      ],
    );
  }

  Widget _buildCateResArea(BuildContext context, CategoryResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("亚项得分情况", style: commonStyles?.titleStyle,),
        const Divider( ),
        Text("亚项名称：${result.name}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("亚项总分：${result.finalScore}", style: commonStyles?.bodyStyle,),
      ],
    );
  }

  Widget _buildSubCateResArea(BuildContext context, SubCategoryResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("子项得分情况", style: commonStyles?.titleStyle,),
        const Divider( ),
        Text("子项名称：${result.name}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("子项总分：${result.finalScore}", style: commonStyles?.bodyStyle,),
      ],
    );
  }

  Widget _buildQuestionResArea(BuildContext context, QuestionResult result) {
    final Question q = result.sourceQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("题目作答情况", style: commonStyles?.titleStyle,),
        const Divider( ),
        Text("题目名称：${q.alias ?? q.defaultQuestionName()}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("题目类型：${q.defaultQuestionName()}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("题目得分：${result.finalScore}/${q.evalRule!.fullScore}", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("开始作答时间：第${result.answerTime}秒", style: commonStyles?.bodyStyle,),
        const SizedBox(height: 16,),
        Text("是否经过提示：${result.isHinted ? "是" : "否"}", style: commonStyles?.bodyStyle,),
        ...result.extraResults.entries.fold(<Widget>[], (prev, e) {
          return prev.toList()..addAll([
            const SizedBox(height: 16,),
            Text("${e.key}：${e.value}", style: commonStyles?.bodyStyle,),
          ]);
        }),
      ],
    );
  }
}