import 'dart:convert';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/widgets/ui/answer_result.dart';
import 'package:flutter/material.dart';

import '../../../models/exam/category.dart';
import '../../../models/exam/sub_category.dart';

class DoExamPage extends StatefulWidget {
  final ExamQuestionSet exam;
  final CommonStyles? commonStyles;
  final ExamResult result;

  const DoExamPage(
      {super.key,
      required this.exam,
      required this.commonStyles,
      required this.result});

  @override
  State<DoExamPage> createState() => _DoExamPageState();
}

class _DoExamPageState extends State<DoExamPage> with UseCommonStyles {
  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _pagePadding = 16.0;
  static const _progressBarHeight = 4.0;

  late ExamQuestionSet exam;
  int categoryIndex = 0;
  int subCategoryIndex = 0;
  int questionIndex = 0;
  late ExamResult examResult;

  void goToNextQuestion(QuestionResult result) {
    final category = exam.categories[categoryIndex];
    final subCategory = category.subCategories[subCategoryIndex];

    examResult.categoryResults[categoryIndex].subResults[subCategoryIndex]
        .addQuestionResult(result);

    ExamResult.saveExamResult(result: examResult).then((value) {
      examResult = value;
      questionIndex++;

      // debugPrint(examResult.toJson().toString());
      debugPrint("检查第$categoryIndex亚项第$subCategoryIndex子项是否需要终止");
      bool checkTerminate() {
        return subCategory.checkIfTerminate(
            examResult
                .categoryResults[categoryIndex].subResults[subCategoryIndex],
            questionIndex);
      }

      if (questionIndex == subCategory.questions.length || checkTerminate()) {
        debugPrint("第$categoryIndex亚项第$subCategoryIndex子项结束");
        _evalSubCategory(
            subCategory,
            examResult
                .categoryResults[categoryIndex].subResults[subCategoryIndex]);

        questionIndex = 0;
        subCategoryIndex++;
      }

      if (subCategoryIndex == category.subCategories.length) {
        debugPrint("第$categoryIndex亚项结束");
        _evalCategory(category, examResult.categoryResults[categoryIndex]);

        subCategoryIndex = 0;
        categoryIndex++;
      }

      if (categoryIndex == exam.categories.length) {
        _evalExam(exam, examResult);
        examResult.finishTime = DateTime.now();
        examResult.isDisabled = false;
        ExamResult.saveExamResult(result: examResult).then((value) {
          examResult = value;
          debugPrint(jsonEncode(value.toJson()));
          if (context.mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => AnswerResultPage(
                        commonStyles: commonStyles, examResult: value)));
          }
        });
      } else {
        // 刷新state，显示下一题
        setState(() {});
        debugPrint(
            "进入下一题：第${categoryIndex + 1}亚项;第${subCategoryIndex + 1}子项;第${questionIndex + 1}道题目");
      }
    }).catchError((error) {
      requestResultErrorHandler(context, error: error);
      return error;
    });
  }

  void _evalExam(ExamQuestionSet exam, ExamResult result) {
    // for (var e in exam.rules) {
    //   e.evaluate(result);
    // }

    var i = 0;
    for (var e in exam.diagnosisRules) {
      debugPrint("检查第$i条诊断规则：${e.runtimeType.toString()}");
      e.checkAndDiagnose(result);
      i++;
    }
  }

  void _evalCategory(QuestionCategory category, CategoryResult result) {
    for (var e in category.rules) {
      e.evaluate(result);
    }
  }

  void _evalSubCategory(
      QuestionSubCategory subCategory, SubCategoryResult result) {
    for (var e in subCategory.evalRules) {
      e.evaluate(result);
    }
  }

  void initExamResult() {
    for (var category in exam.categories) {
      var categoryRes = CategoryResult(name: category.description);
      for (var subCate in category.subCategories) {
        categoryRes.subResults
            .add(SubCategoryResult(name: subCate.description));
      }
      examResult.categoryResults.add(categoryRes);
    }
    examResult.startTime = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    exam = widget.exam;
    commonStyles = widget.commonStyles;

    examResult = widget.result;
    // TODO: 正式环境删除下面两行
    // if (examResult.categoryResults.isEmpty) {
    //   initExamResult();
    // }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = exam.categories[categoryIndex];
    final subCategory = category.subCategories[subCategoryIndex];
    final currQuestion = subCategory.questions[questionIndex];

    // return Scaffold(
    //   appBar: AppBar(
    //     leading: BackButton(
    //       onPressed: () {
    //         Navigator.pop(context);
    //       },
    //     ),
    //     title: Row(
    //       children: [
    //         Text(
    //           "当前：${exam.name}/${category.description}/${subCategory.description}/${currQuestion.alias}",
    //           style: commonStyles?.bodyStyle,
    //           overflow: TextOverflow.ellipsis,
    //         ),
    //       ],
    //     ),
    //     bottom: PreferredSize(
    //       preferredSize: const Size.fromHeight(4),
    //       child: LinearProgressIndicator(
    //         value: (categoryIndex + 1) / exam.categories.length,
    //         backgroundColor: Colors.grey[300],
    //         valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
    //       ),
    //     ),
    //   ),
    //   // body: SafeArea(
    //   //   child: _buildAnswerArea(context, question: currQuestion),
    //   // ));
    //   body: SafeArea(
    //     child: Padding(
    //       padding: const EdgeInsets.all(16.0),
    //       child: Card(
    //         elevation: 8,
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(20),
    //         ),
    //         child: Padding(
    //           padding: const EdgeInsets.all(20),
    //           child: _buildAnswerArea(context, question: currQuestion),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: commonStyles?.primaryColor, // 统一按钮颜色
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildProgressIndicator(
                category: category, // 添加参数传递
                subCategory: subCategory), // 提取进度指示器组件
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_progressBarHeight),
          child: LinearProgressIndicator(
            value: (categoryIndex + 1) / exam.categories.length,
            backgroundColor: commonStyles?.onPrimaryColor?.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
                commonStyles?.primaryColor ?? Colors.blueAccent),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_pagePadding),
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
                      commonStyles?.primaryColor?.withOpacity(0.03) ??
                          Colors.white,
                      commonStyles?.onPrimaryColor?.withOpacity(0.05) ??
                          Colors.white,
                    ]),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildAnswerArea(context, question: currQuestion),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      {required QuestionCategory category, // 添加参数声明
      required QuestionSubCategory subCategory}) {
    return Row(
      children: [
        Icon(Icons.auto_awesome, color: commonStyles?.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "${exam.name} > ${category.description} > ${subCategory.description}",
            style: commonStyles?.bodyStyle?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: commonStyles?.errorColor ?? Colors.redAccent),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerArea(BuildContext context, {required Question question}) {
    // return Center(
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 500),
//         transitionBuilder: (Widget child, Animation<double> animation) {
// //               return ScaleTransition(scale: animation, child: child);
//           return SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(2.0, 0.0),
//               end: Offset.zero,
//             ).animate(animation),
//             child: child,
//           );
//         },
//         // child: question.buildAnswerAreaWidget(
//         //   context,
//         //   commonStyles: commonStyles,
//         //   goToNextQuestion: goToNextQuestion,
//         // ),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: question.buildAnswerAreaWidget(
//               context,
//               commonStyles: commonStyles,
//               goToNextQuestion: goToNextQuestion,
//             ),
//           ),
//         ),
//       ),
//     );
//     return Center(
//       child: question.buildAnswerAreaWidget(
//         context,
//         commonStyles: commonStyles,
//         goToNextQuestion: goToNextQuestion,
//       ),
//     );
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        ),
        child: Card(
          key: ValueKey(question.id), // 确保动画触发
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius - 4),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(_cardRadius - 4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: question.buildAnswerAreaWidget(
                context,
                commonStyles: commonStyles,
                goToNextQuestion: goToNextQuestion,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
