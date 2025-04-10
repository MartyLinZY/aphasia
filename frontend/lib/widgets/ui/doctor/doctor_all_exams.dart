import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/settings.dart';

import '../../../models/exam/exam_recovery.dart';
import '../../../states/user_identity.dart';
import 'doctor_exam_edit.dart';

class DoctorAllExamsListPage extends StatefulWidget {
  final bool isRecovery;
  final CommonStyles? commonStyles;
  final double cardRadius;
  const DoctorAllExamsListPage(
      {super.key,
      this.isRecovery = false,
      required this.commonStyles,
      this.cardRadius = 12.0});

  @override
  State<DoctorAllExamsListPage> createState() => _DoctorAllExamsListPageState();
}

class _DoctorAllExamsListPageState extends State<DoctorAllExamsListPage>
    with UseCommonStyles {
  static const _cardRadius = 8.0;
  static const _listHoverColor = Colors.black12;
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
    TextStyle? hintTextStyle = theme.textTheme.displaySmall!
        .copyWith(color: theme.colorScheme.onPrimary);

    if (media.size.height > 600) {
      titleStyle = theme.textTheme.titleLarge!;
      bodyStyle = theme.textTheme.bodyLarge!;
      hintTextStyle = theme.textTheme.displayMedium
          ?.copyWith(color: theme.colorScheme.onPrimary);
    }

    return FutureBuilder<List<ExamQuestionSet>?>(
        future: futureExams,
        builder: (BuildContext context, snapshot) {
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
                            LayoutBuilder(builder: (context, constraints) {
                              return SizedBox(
                                height: 82,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "套题列表",
                                      style: titleStyle,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            SizedBox(
                              height: 32,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Material(
                                    elevation: 2,
                                    borderRadius:
                                        BorderRadius.circular(_cardRadius),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary
                                              .withOpacity(0.8)
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(_cardRadius),
                                      ),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      DoctorExamEditInstructionPage(
                                                        recoveryMode:
                                                            isRecovery ?? false,
                                                      ))).then((value) {
                                            setState(() {});
                                          });
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: theme.colorScheme.onPrimary,
                                          size: 18,
                                        ),
                                        label: Text(
                                          "新建",
                                          style: bodyStyle.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: SafeArea(
                                child: exams.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        itemCount: exams.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return ListTile(
                                            onTap: () =>
                                                onListTileTapped(index),
                                            selected:
                                                selectedExamIndex == index,
                                            selectedTileColor: theme
                                                .colorScheme.inversePrimary,
                                            selectedColor:
                                                theme.colorScheme.onPrimary,
                                            tileColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        _cardRadius)),
                                            hoverColor: _listHoverColor,
                                            title: Row(
                                              children: [
                                                Icon(
                                                  exams[index].recovery
                                                      ? Icons.healing
                                                      : Icons.assignment,
                                                  size: 20,
                                                  color:
                                                      selectedExamIndex == index
                                                          ? theme.colorScheme
                                                              .onPrimary
                                                          : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    exams[index].name,
                                                    style: bodyStyle.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          selectedExamIndex ==
                                                                  index
                                                              ? theme
                                                                  .colorScheme
                                                                  .onPrimary
                                                              : Colors
                                                                  .grey[800],
                                                    ),
                                                  ),
                                                ),
                                                if (exams[index].published)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      "已发布",
                                                      style: bodyStyle.copyWith(
                                                          color: Colors.green,
                                                          fontSize: 12),
                                                    ),
                                                  )
                                              ],
                                            ),
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
                          child: Builder(builder: (context) {
                            if (selectedExamIndex == null) {
                              return Text(
                                "点击左侧套题查看详情",
                                style: hintTextStyle,
                              );
                            } else if (selectedExamIndex! >= exams.length) {
                              // should not happen
                              throw UnimplementedError();
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(36.0),
                                child: FractionallySizedBox(
                                  widthFactor: 0.8,
                                  child: ExamDetailCard(
                                    exam: exams[selectedExamIndex!],
                                    index: selectedExamIndex!,
                                    parentState: this,
                                    commonStyles: commonStyles,
                                    bodyStyle: bodyStyle,
                                  ),
                                ),
                              );
                            }
                          }),
                        ),
                      ))
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
            return Center(
                child: Text(
              "加载中",
              style: hintTextStyle?.copyWith(color: Colors.grey),
            ));
          } else {
            return Center(
                child: Text(
              "加载中",
              style: hintTextStyle?.copyWith(color: Colors.grey),
            ));
          }
        });
  }

  Future<void> refreshExam() async {
    futureExams = ExamQuestionSet.getByDoctorUserId(
        userId: context.read<UserIdentity>().uid,
        getRecovery: isRecovery ?? false);
  }

  // 新增空状态提示组件
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "暂无可用套题",
            style: commonStyles?.titleStyle
                ?.copyWith(color: Colors.grey[700], fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "当前没有已启用的套题，请新建或启用已有套题",
            style: commonStyles?.bodyStyle
                ?.copyWith(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

class ExamDetailCard extends StatelessWidget {
  static const _cardRadius = 8.0;
  final ExamQuestionSet exam;
  final int index;
  final _DoctorAllExamsListPageState _parentState;
  final CommonStyles? commonStyles;
  final TextStyle bodyStyle;
  static final HttpClientManager _instance = HttpClientManager();

  const ExamDetailCard({
    super.key,
    required this.exam,
    required this.index,
    required State<DoctorAllExamsListPage> parentState,
    required this.commonStyles,
    required this.bodyStyle,
  })  : assert(parentState is _DoctorAllExamsListPageState),
        _parentState = parentState as _DoctorAllExamsListPageState;

  // const ExamDetailCard(
  //     {super.key,
  //     required this.exam,
  //     required this.index,
  //     required State<DoctorAllExamsListPage> parentState,
  //     required this.commonStyles})
  //     : assert(parentState is _DoctorAllExamsListPageState),
  //       _parentState = parentState as _DoctorAllExamsListPageState
  // 修改构造函数

  List<Widget> _buildCategoryWidgets(ThemeData theme) {
    List<Widget> categoryWidgets = [];
    for (int i = 0; i < exam.categories.length; i++) {
      final category = exam.categories[i];
      List<Widget> subCategoryWidgets = [];

      for (int j = 0; j < category.subCategories.length; j++) {
        final subCategory = category.subCategories[j];
        List<Widget> questionWidgets = [];

        for (int k = 0; k < subCategory.questions.length; k++) {
          final question = subCategory.questions[k];
          questionWidgets.add(ListTile(
            contentPadding: const EdgeInsets.only(left: 24),
            leading: Text("${k + 1}.",
                style: bodyStyle.copyWith(color: Colors.grey[600])),
            title: Text(
              question.alias ?? question.defaultQuestionName(),
              style: bodyStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ));
        }

        subCategoryWidgets.add(Material(
          borderRadius: BorderRadius.circular(_cardRadius),
          elevation: 1,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title:
                Text("${j + 1}. ${subCategory.description}", style: bodyStyle),
            children: questionWidgets,
          ),
        ));
      }

      categoryWidgets.add(Material(
        borderRadius: BorderRadius.circular(_cardRadius),
        elevation: 2,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text("${i + 1}. ${category.description}",
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600)),
          children: subCategoryWidgets,
        ),
      ));
    }
    return categoryWidgets;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    List<Widget> categoryWidgets = _buildCategoryWidgets(theme);
    // var media = MediaQuery.of(context);
    // TextStyle titleStyle = theme.textTheme.titleMedium!;
    // TextStyle bodyStyle = theme.textTheme.bodyMedium!;
    // TextStyle? hintTextStyle = theme.textTheme.displaySmall!.copyWith(color: theme.colorScheme.onPrimary);

    // if (media.size.height > 600) {
    //   titleStyle = theme.textTheme.titleLarge!;
    //   bodyStyle = theme.textTheme.bodyLarge!;
    //   hintTextStyle = theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary);
    // }
    // // var categoryWidgets = <Widget>[];
    // for (int i = 0;i < exam.categories.length;i++) {
    //   var category = exam.categories[i];
    //   var subCategoryWidgets = <Widget>[];
    //   for (int j = 0;j < category.subCategories.length;j++) {
    //     var subCategory = category.subCategories[j];
    //     var questionWidgets = <Widget>[];
    //     for (int k = 0;k < subCategory.questions.length;k++) {
    //       var question = subCategory.questions[k];
    //       questionWidgets.add(ListTile(
    //         title: Text("${k + 1}. ${question.alias ?? question.defaultQuestionName()}"),
    //       ));
    //     }

    //     subCategoryWidgets.add(ExpansionTile(
    //       title: Text("${j + 1}. ${subCategory.description}"),
    //       children: questionWidgets,
    //     ));
    //   }

    //   categoryWidgets.add(ExpansionTile(
    //     title: Text("${i + 1}. ${category.description}"),
    //     children: subCategoryWidgets,
    //   ));
    // }

    // return Material(
    //   elevation: 8.0,
    //   borderRadius: BorderRadius.circular(5.0),
    //   child: LayoutBuilder(
    //     builder: (context, constraints) {
    //       return SingleChildScrollView(
    //         child: Column(
    //           children: [
    //             Padding(
    //               padding: const EdgeInsets.only(left: 16),
    //               child: Padding(
    //                 padding: const EdgeInsets.only(top: 16.0),
    //                 child: Row(
    //                   mainAxisAlignment: MainAxisAlignment.start,
    //                   crossAxisAlignment: CrossAxisAlignment.center,
    //                   children: [
    //                     ElevatedButton(
    //                       onPressed: () {
    //                         Navigator.push(context, MaterialPageRoute(
    //                             builder: (context) => ChangeNotifierProvider.value(
    //                               value: ExamState(exam),
    //                               child: const DoctorExamEditPage(),
    //                             ))).then((value) => _parentState.setState(() {}));
    //                       },
    //                       style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
    //                       child: Text("编辑", style: bodyStyle.copyWith(color: theme.colorScheme.onPrimary),),
    //                     ),
    //                     const SizedBox(width: 16,),
    //                     ElevatedButton(
    //                       onPressed: () {
    //                         showDialog(context: context, builder: (context) => Builder(
    //                           builder: (context) {
    //                             TextEditingController controller = TextEditingController();

    //                             return AlertDialog(
    //                               title: Text("二次确认", style: titleStyle,),
    //                               content: Column(
    //                                 mainAxisSize: MainAxisSize.min,
    //                                 children: [
    //                                   Text('如果确认要永久删除该套题，请在下面输入"立即删除"然后点击删除按钮。', style: bodyStyle,),
    //                                   TextField(
    //                                     decoration: InputDecoration(
    //                                       hintText: "在此输入",
    //                                       hintStyle: bodyStyle.copyWith(color: Colors.grey)
    //                                     ),
    //                                     controller: controller,
    //                                   ),
    //                                 ],
    //                               ),
    //                               actions: [
    //                                 ElevatedButton(
    //                                   key: const Key("cancelBtnOnConfirmDialog"),
    //                                   onPressed: () {
    //                                     Navigator.pop(context);
    //                                   },
    //                                   child: Text("取消", style: bodyStyle,)
    //                                 ),
    //                                 ElevatedButton(
    //                                   key: const Key("confirmBtnOnConfirmDialog"),
    //                                   onPressed: () {
    //                                     if (controller.text == "立即删除") {
    //                                       _parentState.refreshExam();
    //                                       Navigator.pop(context);
    //                                     }
    //                                   },
    //                                   style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
    //                                   child: Text("删除", style: bodyStyle.copyWith(color: theme.colorScheme.onError),),
    //                                 )
    //                               ],
    //                               actionsAlignment: MainAxisAlignment.end,
    //                             );
    //                           }
    //                         ));
    //                       },
    //                       style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
    //                       child: Text("删除", style: bodyStyle.copyWith(color: theme.colorScheme.onPrimary),),
    //                     )
    //                   ],
    //                 ),
    //               ),
    //             ),
    //             SizedBox(
    //               height: 82,
    //               child: Column(
    //                 children: [
    //                   Expanded(flex: 2, child: Text("套题名称：${exam.name}", style: titleStyle,)),
    //                   Expanded(flex: 1, child: SelectableText("套题ID:${exam.id}", style: bodyStyle,)),
    //                   Expanded(flex: 1, child: Text('套题发布状况:${exam.published ?"已发布": "未发布"}', style: bodyStyle,)),
    //                 ],
    //               ),
    //             ),
    //             const SizedBox(height: 8,),
    //             SizedBox(
    //               height: 82,
    //               child: Text("简介：${exam.description}", style: titleStyle.copyWith(color: Colors.grey),),
    //             ),
    //             const Divider(),
    //             Text("题目目录：", style: bodyStyle,),
    //             Padding(
    //               padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
    //               child: Container(
    //                 constraints: BoxConstraints(minHeight: 600, minWidth: constraints.maxWidth),
    //                 decoration: BoxDecoration(
    //                   border: Border.all(
    //                     color: Colors.black26,
    //                     width: 2.0,
    //                   ),
    //                 ),
    //                 child: Column(
    //                   children: categoryWidgets.isNotEmpty
    //                       ? categoryWidgets
    //                       : [Text("暂无题目，请点击左上角编辑按钮添加题目", style: commonStyles?.bodyStyle,)],
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     }
    //   ),
    // );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    exam.recovery ? Icons.healing : Icons.assignment,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    exam.name,
                    style: theme.textTheme.titleLarge!.copyWith(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoItem("套题ID:", exam.id ?? '未知'),
                  _buildInfoItem("发布状态:", exam.published ? "已发布" : "未发布",
                      color: exam.published ? Colors.green : Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!exam.published) // 新增发布状态判断
                    _buildActionButton(
                        icon: Icons.edit,
                        label: "编辑",
                        color: theme.colorScheme.primary,
                        onPressed: () {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ChangeNotifierProvider.value(
                                            value: ExamState(exam),
                                            child: const DoctorExamEditPage(),
                                          )))
                              .then((value) => _parentState.setState(() {}));
                        }),
                    const SizedBox(width: 16),
                  _buildActionButton(
                      icon: Icons.delete,
                      label: "删除",
                      color: theme.colorScheme.error,
                      onPressed: () => _showDeleteConfirmationDialog(context)),
                  if (!exam.published) ...[
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.publish,
                      label: "发布",
                      color: Colors.green,
                      onPressed: () => _publishExam(context),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 32),
              Text("题目目录", style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: _buildQuestionCatalog(categoryWidgets),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 新增辅助方法
  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label ", style: bodyStyle.copyWith(color: Colors.grey[600])),
        Text(value, style: bodyStyle.copyWith(color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(label, style: bodyStyle.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("二次确认", style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('如果确认要永久删除该套题，请在下面输入"立即删除"然后点击删除按钮。',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "在此输入",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_cardRadius),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消", style: theme.textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text == "立即删除") {
                final success = await delete(context); // 实际调用删除接口
                if (!success) throw Exception('后端返回操作失败');

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("删除成功", style: commonStyles?.bodyStyle)));
                _parentState.refreshExam();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("输入内容不匹配，删除操作已取消",
                          style: commonStyles?.bodyStyle
                              ?.copyWith(color: Colors.white))),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text("确认删除", style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCatalog(List<Widget> categories) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (_, i) => categories[i],
        ),
      ),
    );
  }

  void _publishExam(BuildContext context) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("发布确认", style: theme.textTheme.titleLarge),
        content: Text("确定要发布该套题吗？发布后不可撤销且无法修改内容。",
            style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("取消", style: theme.textTheme.bodyMedium)),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context); // 先关闭对话框
                await exam.publish();
                await _parentState.refreshExam();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("发布成功",
                      style: commonStyles?.bodyStyle
                          ?.copyWith(color: Colors.white)),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("发布失败: ${e.toString()}",
                      style: commonStyles?.bodyStyle
                          ?.copyWith(color: Colors.white)),
                  backgroundColor: Colors.red,
                ));
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text("确认发布", style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<bool> delete(BuildContext context) async {
    try {
      await HttpClientManager()
          .delete(url: "${HttpConstants.backendBaseUrl}/api/exams/${exam.id}")
          .catchError((err) {
        requestResultErrorHandler(context, error: err);
        return err;
      });
      return true;
    } catch (e) {
      debugPrint('删除请求失败: $e');
      return false;
    }
  }
}
