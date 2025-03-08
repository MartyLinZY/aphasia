
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


class DoRecoveryPage extends StatefulWidget {
  final ExamQuestionSet exam;
  final CommonStyles? commonStyles;
  final ExamResult result;

  const DoRecoveryPage(
      {super.key,
      required this.exam,
      required this.commonStyles,
      required this.result});

  @override
  State<DoRecoveryPage> createState() => _DoRecoveryPageState();
}

class _DoRecoveryPageState extends State<DoRecoveryPage> with UseCommonStyles {
  late ExamQuestionSet exam;
  int categoryIndex = 0;
  int subCategoryIndex = 0;
  int questionIndex = 0;
  late ExamResult recoveryResult;

  bool showingResult = false;

  void goToNextQuestion(QuestionResult result) {
    final category = exam.categories[categoryIndex];
    final subCategory = category.subCategories[subCategoryIndex];

    recoveryResult.categoryResults[categoryIndex].subResults[subCategoryIndex]
        .addQuestionResult(result);

    // TODO: 保存康复结果到后端
    ExamResult.saveExamResult(result: recoveryResult).then((value) {
      recoveryResult = value;

      questionIndex++;

      if (questionIndex == subCategory.questions.length) {
        debugPrint("第$categoryIndex亚项第$subCategoryIndex子项结束");
        _evalSubCategory(
            subCategory,
            recoveryResult
                .categoryResults[categoryIndex].subResults[subCategoryIndex]);

        questionIndex = 0;
        subCategoryIndex++;
      }

      if (subCategoryIndex == category.subCategories.length) {
        debugPrint("第$categoryIndex亚项结束");
        _evalCategory(category, recoveryResult.categoryResults[categoryIndex]);

        subCategoryIndex = 0;
        categoryIndex++;
      }

      if (categoryIndex == exam.categories.length) {
        _evalExam(exam, recoveryResult);
        recoveryResult.finishTime = DateTime.now();

        ExamResult.saveExamResult(result: recoveryResult).then((value) {
          recoveryResult = value;
          debugPrint(jsonEncode(value.toJson()));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnswerResultPage(commonStyles: commonStyles, examResult: value)));
        }).catchError((error) { requestResultErrorHandler(context, error: error); return error;});

      } else {
        showingResult = true; // 注意这一句会使setState不生效，从而实现暂停答题的效果，但是副作用是结果展示dialog的内容无法变化，如果有动态改变结果展示dialog内容的需求，需要重写展示结果时暂停答题的逻辑
        // 弹窗显示结果，点击确认后，刷新state，显示下一题
        showResultAndGotoNext(result);
      }
    }).catchError((error) { requestResultErrorHandler(context, error: error); return error;});
  }

  void showResultAndGotoNext(QuestionResult result) {
    showDialog(context: context, barrierDismissible: false, builder: (context) {
      final Question q = result.sourceQuestion;
      return AlertDialog(
        title: Text("作答结果", style: commonStyles?.titleStyle,),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () {
            showingResult = false;
            Navigator.pop(context);
            setState(() { });
            debugPrint("进入下一题：第${categoryIndex + 1}亚项;第${subCategoryIndex+1}子项;第${questionIndex+1}道题目");
          }, child: Text("下一题", style: commonStyles?.bodyStyle,))
        ],
      );
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
      recoveryResult.categoryResults.add(categoryRes);
    }
    recoveryResult.startTime = DateTime.now();
  }


  @override
  void initState() {
    super.initState();
    exam = widget.exam;
    commonStyles = widget.commonStyles;

    recoveryResult = widget.result;
    // TODO: 正式环境删除下面两行
    if (recoveryResult.categoryResults.isEmpty) {
      initExamResult();
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (showingResult) {
      return;
    }

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

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("< 暂时退出",
                    style:
                        commonStyles?.bodyStyle?.copyWith(color: Colors.blue),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                "当前：${exam.name}/${category.description}/${subCategory.description}/${currQuestion.alias}",
                style: commonStyles?.bodyStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _buildAnswerArea(context, question: currQuestion),
        ));
  }

  Widget _buildAnswerArea(BuildContext context, {required Question question}) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
//               return ScaleTransition(scale: animation, child: child);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(2.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: question.buildAnswerAreaWidget(
          context,
          commonStyles: commonStyles,
          goToNextQuestion: goToNextQuestion,
        ),
      ),
    );
//     return Center(
//       child: question.buildAnswerAreaWidget(
//         context,
//         commonStyles: commonStyles,
//         goToNextQuestion: goToNextQuestion,
//       ),
//     );
  }
}
