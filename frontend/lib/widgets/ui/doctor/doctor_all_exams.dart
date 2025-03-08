import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/exam_recovery.dart';
import '../../../states/user_identity.dart';
import 'doctor_exam_edit.dart';

class DoctorAllExamsListPage extends StatefulWidget {
  final bool isRecovery;
  final CommonStyles? commonStyles;
  const DoctorAllExamsListPage({super.key, this.isRecovery = false, required this.commonStyles});

  @override
  State<DoctorAllExamsListPage> createState() => _DoctorAllExamsListPageState();
}

class _DoctorAllExamsListPageState extends State<DoctorAllExamsListPage> with UseCommonStyles {
  bool? isRecovery;

  Future<List<ExamQuestionSet>?> futureExams = Future(() => null);
  int? selectedExamIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    if (isRecovery != widget.isRecovery) {
      isRecovery = widget.isRecovery;
      selectedExamIndex = null;
      refreshExam();
    }

    var theme = Theme.of(context);
    var media = MediaQuery.of(context);

    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle bodyStyle = theme.textTheme.bodyMedium!;
    TextStyle? hintTextStyle = theme.textTheme.displaySmall!.copyWith(color: theme.colorScheme.onPrimary);

    if (media.size.height > 600) {
      titleStyle = theme.textTheme.titleLarge!;
      bodyStyle = theme.textTheme.bodyLarge!;
      hintTextStyle = theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary);
    }

    return FutureBuilder<List<ExamQuestionSet>?>(future: futureExams, builder: (BuildContext context, snapshot) {
      if (snapshot.hasData) {
        onListTileTapped(int index) {
          setState(() {
            selectedExamIndex = index;
          });
        }

        List<ExamQuestionSet> exams = snapshot.requireData!;
        return Container(
          constraints: const BoxConstraints(minWidth: 1000),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 250),
                  child: Material(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 82,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("套题列表", style: titleStyle,),
                                ),
                              ),
                            );
                          }
                        ),
                        SizedBox(
                          height: 32,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 8.0)),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorExamEditInstructionPage(recoveryMode: isRecovery ?? false,)))
                                    .then((value) {
                                      setState(() {});
                                  });
                                },
                                icon: Icon(Icons.add,
                                  color: theme.colorScheme.onPrimary,
                                  size: 18,
                                ),
                                label: Text("新建", style: bodyStyle.copyWith(color: theme.colorScheme.onPrimary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: SafeArea(
                            child: ListView.builder(
                              itemCount: exams.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  onTap: () {
                                    onListTileTapped(index);
                                  },
                                  selected: selectedExamIndex == index,
                                  selectedTileColor: theme.colorScheme.inversePrimary,
                                  selectedColor: theme.colorScheme.onPrimary,
                                  title: Text(
                                    exams[index].name,
                                    style:  selectedExamIndex == index? bodyStyle.copyWith(color: theme.colorScheme.onPrimary): bodyStyle,
                                  ),
                                  leading: const Text("E"),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 500),
                  color: theme.colorScheme.primaryContainer,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        if (selectedExamIndex == null) {
                          return Text("点击左侧套题查看详情", style: hintTextStyle,);
                        } else if (selectedExamIndex! >= exams.length) {
                          // should not happen
                          throw UnimplementedError();
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(36.0),
                            child: FractionallySizedBox(
                              widthFactor: 0.8,
                              child: ExamDetailCard(exam: exams[selectedExamIndex!], index: selectedExamIndex!, parentState: this, commonStyles: commonStyles,),
                            ),
                          );
                        }
                      }
                    ),
                  ),
                )
              )
            ],
          ),
        );
      } else if (snapshot.hasError) {
        debugPrint(snapshot.error.toString());
        if (snapshot.error is ClientException) {
          debugPrint((snapshot.error as ClientException).toString());
          debugPrintStack();
        } else {
          debugPrint((snapshot.error as Error).stackTrace.toString());
        }

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          toast(context, msg: "获取测评和康复方案数据失败，请检查网络情况", btnText: "确认");
        });
        return Center(child: Text("加载中", style: hintTextStyle?.copyWith(color: Colors.grey),));
      } else {
        return Center(child: Text("加载中", style: hintTextStyle?.copyWith(color: Colors.grey),));
      }
    });
  }

  Future<void> refreshExam() async {
    futureExams =
        ExamQuestionSet.getByDoctorUserId(userId: context
            .read<UserIdentity>()
            .uid, getRecovery: isRecovery ?? false);
  }
}

class ExamDetailCard extends StatelessWidget {
  final ExamQuestionSet exam;
  final int index;
  final _DoctorAllExamsListPageState _parentState;
  final CommonStyles? commonStyles;
  const ExamDetailCard({super.key, required this.exam, required this.index, required State<DoctorAllExamsListPage> parentState, required this.commonStyles})
    : assert (parentState is _DoctorAllExamsListPageState),
      _parentState = parentState as _DoctorAllExamsListPageState;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var media = MediaQuery.of(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle bodyStyle = theme.textTheme.bodyMedium!;
    TextStyle? hintTextStyle = theme.textTheme.displaySmall!.copyWith(color: theme.colorScheme.onPrimary);

    if (media.size.height > 600) {
      titleStyle = theme.textTheme.titleLarge!;
      bodyStyle = theme.textTheme.bodyLarge!;
      hintTextStyle = theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary);
    }
    var categoryWidgets = <Widget>[];
    for (int i = 0;i < exam.categories.length;i++) {
      var category = exam.categories[i];
      var subCategoryWidgets = <Widget>[];
      for (int j = 0;j < category.subCategories.length;j++) {
        var subCategory = category.subCategories[j];
        var questionWidgets = <Widget>[];
        for (int k = 0;k < subCategory.questions.length;k++) {
          var question = subCategory.questions[k];
          questionWidgets.add(ListTile(
            title: Text("${k + 1}. ${question.alias ?? question.defaultQuestionName()}"),
          ));
        }

        subCategoryWidgets.add(ExpansionTile(
          title: Text("${j + 1}. ${subCategory.description}"),
          children: questionWidgets,
        ));
      }

      categoryWidgets.add(ExpansionTile(
        title: Text("${i + 1}. ${category.description}"),
        children: subCategoryWidgets,
      ));
    }

    return Material(
      elevation: 8.0,
      borderRadius: BorderRadius.circular(5.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => ChangeNotifierProvider.value(
                                  value: ExamState(exam),
                                  child: const DoctorExamEditPage(),
                                ))).then((value) => _parentState.setState(() {}));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                          child: Text("编辑", style: bodyStyle.copyWith(color: theme.colorScheme.onPrimary),),
                        ),
                        const SizedBox(width: 16,),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(context: context, builder: (context) => Builder(
                              builder: (context) {
                                TextEditingController controller = TextEditingController();

                                return AlertDialog(
                                  title: Text("二次确认", style: titleStyle,),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('如果确认要永久删除该套题，请在下面输入"立即删除"然后点击删除按钮。', style: bodyStyle,),
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: "在此输入",
                                          hintStyle: bodyStyle.copyWith(color: Colors.grey)
                                        ),
                                        controller: controller,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      key: const Key("cancelBtnOnConfirmDialog"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("取消", style: bodyStyle,)
                                    ),
                                    ElevatedButton(
                                      key: const Key("confirmBtnOnConfirmDialog"),
                                      onPressed: () {
                                        if (controller.text == "立即删除") {
                                          _parentState.refreshExam();
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                      child: Text("删除", style: bodyStyle.copyWith(color: theme.colorScheme.onError),),
                                    )
                                  ],
                                  actionsAlignment: MainAxisAlignment.end,
                                );
                              }
                            ));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
                          child: Text("删除", style: bodyStyle.copyWith(color: theme.colorScheme.onPrimary),),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 82,
                  child: Column(
                    children: [
                      Expanded(flex: 2, child: Text("套题名称：${exam.name}", style: titleStyle,)),
                      Expanded(flex: 1, child: SelectableText("套题ID:${exam.id}", style: bodyStyle,)),
                      Expanded(flex: 1, child: Text('套题发布状况:${exam.published ?"已发布": "未发布"}', style: bodyStyle,)),
                    ],
                  ),
                ),
                const SizedBox(height: 8,),
                SizedBox(
                  height: 82,
                  child: Text("简介：${exam.description}", style: titleStyle.copyWith(color: Colors.grey),),
                ),
                const Divider(),
                Text("题目目录：", style: bodyStyle,),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 600, minWidth: constraints.maxWidth),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black26,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      children: categoryWidgets.isNotEmpty
                          ? categoryWidgets
                          : [Text("暂无题目，请点击左上角编辑按钮添加题目", style: commonStyles?.bodyStyle,)],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

}