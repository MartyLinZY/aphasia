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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      key: const Key("searchInputContainer"),
                      constraints: const BoxConstraints(minWidth: 150, maxWidth: 1000),
                      child: TextField (
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '输入测评或康复方案的ID来开始答题'),
                        controller: searchCtrl,
                        enableInteractiveSelection: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16,),
                  ElevatedButton(
                    key: const Key("searchButton"),
                    onPressed: () {

                      if (searchCtrl.text == "") {
                        return;
                      }

                      ExamQuestionSet.getById(id: searchCtrl.text)
                        .then((exam) {
                          if (exam == null) {
                            toast(context, msg: "找不到该套题，请和医生确认套题是否已发布。", btnText: "确认");
                            return;
                          }

                          bool isRecovery = exam.recovery;
                          ExamResult.createExamResult(exam: exam, isRecovery: isRecovery).then((createdResult) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              if (isRecovery){
                                return DoRecoveryPage(exam: exam, commonStyles: commonStyles, result: createdResult);
                              }

                              return DoExamPage(exam: exam, commonStyles: commonStyles, result: createdResult,);
                            }));
                          });
                      }).catchError((err) {
                        requestResultErrorHandler(context, error:  err);
                        return err;
                      });
                    },
                    child: Text("开始测评/康复训练", style: commonStyles?.bodyStyle,)
                  )
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}