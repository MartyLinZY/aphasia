import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/widgets/ui/answer_result.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../states/user_identity.dart';
import '../../../utils/common_widget_function.dart';

class ExamRecordHistoryPage extends StatefulWidget {
  final bool recoveryMode;
  final CommonStyles? commonStyles;

  const ExamRecordHistoryPage(
      {super.key, this.recoveryMode = false, required this.commonStyles});

  @override
  State<ExamRecordHistoryPage> createState() => _ExamRecordHistoryPageState();
}

class _ExamRecordHistoryPageState extends State<ExamRecordHistoryPage>
    with UseCommonStyles {
  final DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
  late bool recoveryMode;
  bool initialized = false;

  Future<List<ExamResult>> futureExams = Future.value(<ExamResult>[]);

  @override
  void initState() {
    recoveryMode = widget.recoveryMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    if (!initialized || recoveryMode != widget.recoveryMode) {
      recoveryMode = widget.recoveryMode;
      refreshResults(context);
      initialized = true;
    }

    return FutureBuilder<List<ExamResult>>(
        future: futureExams,
        builder:
            (BuildContext context, AsyncSnapshot<List<ExamResult>> snapshot) {
          if (snapshot.hasData) {
            List<ExamResult> results = snapshot.requireData;
            return Container(
              constraints: const BoxConstraints(minWidth: 1000),
              child: Container(
                constraints: const BoxConstraints(minWidth: 250),
                child: Material(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${recoveryMode ? "康复训练" : "测评"}历史记录",
                            style: commonStyles?.titleStyle,
                          ),
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: LayoutBuilder(builder: (context, constraints) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Table(
                                border: TableBorder.all(),
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FlexColumnWidth(0.3),
                                  1: FlexColumnWidth(1.0),
                                  2: FlexColumnWidth(1.3),
                                  3: FlexColumnWidth(1.3),
                                  4: FlexColumnWidth(0.7),
                                  5: FlexColumnWidth(0.7),
                                },
                                children: [
                                  TableRow(children: [
                                    Center(
                                        child: Text(
                                      "序号",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                    )),
                                    Center(
                                        child: Text(
                                      "${recoveryMode ? "康复方案" : "测评量表"}名称",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                    )),
                                    Center(
                                        child: Text(
                                      "开始作答时间",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                    )),
                                    Center(
                                        child: Text(
                                      "结束作答时间",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                    )),
                                    Center(
                                        child: Text(
                                      recoveryMode ? "总得分" : "诊断结果",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                    )),
                                    Center(
                                        child: Text(
                                      "操作",
                                      style: commonStyles?.bodyStyle,
                                      overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                    ))
                                  ]),
                                  ...results.asMap().entries.map((e) {
                                    int index = e.key;
                                    ExamResult result = e.value;

                                    return TableRow(children: [
                                      Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "$index",
                                          style: commonStyles?.bodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      )),
                                      Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          result.examName,
                                          style: commonStyles?.bodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      )),
                                      Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          format.format(result.startTime!),
                                          style: commonStyles?.bodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      )),
                                      Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          result.finishTime != null ? format.format(result.finishTime!) : "未完成",
                                          style: commonStyles?.bodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      )),
                                      Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "${recoveryMode ? result.finalScore ?? "整体不计分" : result.resultText ?? "无诊断"}",
                                          style: commonStyles?.bodyStyle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      )),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: buildListTileContentWithActionButtons(
                                            body: const SizedBox.shrink(),
                                            textAreaMaxHeight: commonStyles?.listTileCommonHeight ?? 32,
                                            textAreaMaxWidth: 0,
                                            commonStyles: commonStyles,
                                            firstBtnIcon: const Icon(Icons.remove_red_eye_sharp),
                                            firstBtnTooltipMsg: "查看",
                                            firstBtnAction: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AnswerResultPage(
                                                              commonStyles:
                                                              commonStyles,
                                                              examResult: result)));
                                            },
                                            secondBtnAction: () {
                                              confirm(context, title: "确认删除", body: "确认要删除该条历史记录吗？删除后不可恢复。", commonStyles: commonStyles,
                                                onConfirm: (context) {
                                                  Navigator.pop(context);

                                                  result.delete().then((_) {
                                                    setState(() {
                                                      refreshResults(context);
                                                    });
                                                  }).catchError((err) {
                                                    requestResultErrorHandler(context, error: err);
                                                    return err;
                                                  });
                                                }
                                              );
                                            },
                                            secondBtnTooltipMsg: "删除",
                                            secondBtnIcon: Icon(Icons.delete_outline, color: commonStyles?.errorColor,)
                                          ),
                                        )
                                      )
                                    ]);
                                  }).toList(),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            debugPrint((snapshot.error as Error).stackTrace.toString());

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              toast(context, msg: "获取测评和康复记录失败，请检查网络情况", btnText: "确认");
            });
            return Center(
                child: Text(
              "加载中",
              style: commonStyles?.hintTextStyle?.copyWith(color: Colors.grey),
            ));
          } else {
            return Center(
                child: Text(
              "加载中",
              style: commonStyles?.hintTextStyle?.copyWith(color: Colors.grey),
            ));
          }
        });
  }

  Future<void> refreshResults(BuildContext context) async {
    // print(context
    //     .read<SingleModelState<UserIdentity>>()
    //     .model!.uid);
    futureExams = ExamResult.getByUid(
        uid: context.read<SingleModelState<UserIdentity>>().model!.uid,
        isRecovery: recoveryMode);
  }
}
