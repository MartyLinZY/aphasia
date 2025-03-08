import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/patient/exam_record_history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@Deprecated("该版本已废弃，重写")
class ExamEntryPatientPage extends StatelessWidget {
  const ExamEntryPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EntryCards(),
          const SizedBox(height: 100,),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamRecordHistoryPage(commonStyles: null,)));
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history),
                Text("我做过的测评记录"),
              ],
            ),
          )
        ]
      ),
    );
  }

}

class ExamEntryDoctorPage extends StatelessWidget {
  const ExamEntryDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EntryCards(),
          const SizedBox(height: 100,),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorExamsManagementPage(commonStyles: null,)));
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person),
                Text("我创建的测评方案"),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class EntryCards extends StatelessWidget {
  const EntryCards( {super.key,} );

  @override
  Widget build(BuildContext context) {

    var theme = Theme.of(context);
    // var cardBackground = theme.cardColor.withRed(255).withBlue(255).withGreen(255);
    var cardTextColor = theme.colorScheme.secondary;
    var cardTitleStyle = theme.textTheme.bodyMedium?.copyWith(color: cardTextColor);
    var cardHintStyle = theme.textTheme.displaySmall?.copyWith(color: cardTextColor);

    double cardWidth = MediaQuery.of(context).size.width * 0.25;
    double cardHeight = MediaQuery.of(context).size.height * 0.3;

    var userInfo = context.watch<UserInfo>();
    var builtinExamCardTitle = "系统内置测评";
    var builtinExamCardContent = "我要自测";
    var searchExamCardTitle = "医生创建的测评";
    var searchExamCardContent = "我有医生的测评编号";
    if (userInfo.role == 2) {
      builtinExamCardTitle = "系统内置测评";
      builtinExamCardContent = "体验内置测评流程";
      searchExamCardTitle = "其他医生创建的测评";
      searchExamCardContent = "搜索其他医生创建的测评方案";
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 250,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Material(
                borderRadius: BorderRadius.circular(12.5),
                child: InkWell(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(builtinExamCardTitle, style: cardTitleStyle,),
                        Expanded(child: Center(child: Text(builtinExamCardContent, style: cardHintStyle,))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Material(
                borderRadius: BorderRadius.circular(12.5),
                child: InkWell(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(searchExamCardTitle, style: cardTitleStyle,),
                        Expanded(child: Center(child: Text(searchExamCardContent, style: cardHintStyle,))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
