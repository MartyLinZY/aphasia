import 'package:aphasia_recovery/enum/radio.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/do_exam.dart';
import 'package:aphasia_recovery/widgets/ui/do_recovery/do_recovery.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  final CommonStyles? commonStyles;
  const SearchPage({super.key, required this.commonStyles});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> implements ResettableState {
  final searchCtrl = TextEditingController();
  late CommonStyles? commonStyles;
  QuestionSetType? type = QuestionSetType.exam;
  static const _inputRadius = 12.0;
  static const _buttonPadding =
  EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  @override
  void resetState() {
    commonStyles = widget.commonStyles;
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  @override
  Widget build(BuildContext context) {
    if (commonStyles != widget.commonStyles) {
      resetState();
    }

    return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 新增输入框标签
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "输入测评/康复方案ID",
                        style: commonStyles?.bodyStyle?.copyWith(
                            color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ),
                    // 优化输入框和按钮布局
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(_inputRadius),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: '例如：67cfxxxxxxxxxxxdb',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.blueAccent),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20)),
                              controller: searchCtrl,
                              enableInteractiveSelection: true,
                              autofocus: true,
                              textInputAction: TextInputAction.go,
                              onSubmitted: (_) => _handleSearch(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 优化按钮样式
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(_inputRadius),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.blueAccent,
                                Colors.lightBlue[400]!
                              ]),
                              borderRadius: BorderRadius.circular(_inputRadius),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: _buttonPadding,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(_inputRadius))),
                              onPressed: _handleSearch,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    "开始训练",
                                    style: commonStyles?.bodyStyle?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    // 新增帮助提示
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "请输入医生提供的方案ID",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  // 新增处理方法
  void _handleSearch() async {
    if (searchCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("请输入有效的测评/康复方案ID")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("正在加载方案..."),
          ],
        ),
      ),
    );

    try {
      final exam = await ExamQuestionSet.getById(id: searchCtrl.text);
      if (!mounted) return;

      Navigator.pop(context); // 关闭加载对话框

      if (exam == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("未找到相关方案，请检查ID是否正确")));
        return;
      }

      final createdResult = await ExamResult.createExamResult(
          exam: exam, isRecovery: exam.recovery);

      if (!mounted) return;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => exam.recovery
                  ? DoRecoveryPage(
                  exam: exam,
                  commonStyles: commonStyles,
                  result: createdResult)
                  : DoExamPage(
                  exam: exam,
                  commonStyles: commonStyles,
                  result: createdResult)));
    } catch (err) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载对话框
      requestResultErrorHandler(context, error: err);
    }
  }
}
