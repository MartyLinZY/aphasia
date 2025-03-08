import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:aphasia_recovery/deprecated/doctor_recovery_management.dart';
import 'package:aphasia_recovery/deprecated/patient_starred_recovery.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@Deprecated("该版本已废弃，重写")
class RecoveryEntryPatientPage extends StatelessWidget {
  const RecoveryEntryPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EntryCards(),
          const SizedBox(height: 100,),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PatientStarredRecoveryPage()));
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star),
                Text("我收藏的康复方案")
              ],
            )
          )
        ],
      ),
    );
  }
}

class RecoveryEntryDoctorPage extends StatelessWidget {
  const RecoveryEntryDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EntryCards(),
          const SizedBox(height: 100,),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorRecoveryManagementPage()));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person),
                  Text("我创建的康复方案")
                ],
              )
          )
        ],
      ),
    );
  }
}

class _EntryCards extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var cardBackground = theme.cardColor.withRed(255).withBlue(255).withGreen(
        255);
    var cardTextColor = theme.colorScheme.secondary;
    var cardTitleStyle = theme.textTheme.bodyMedium?.copyWith(
        color: cardTextColor);
    var cardHintStyle = theme.textTheme.displaySmall?.copyWith(
        color: cardTextColor);

    double cardWidth = MediaQuery
        .of(context)
        .size
        .width * 0.25;
    double cardHeight = MediaQuery
        .of(context)
        .size
        .height * 0.3;

    var userInfo = context.watch<UserInfo>();
    var builtinRecoveryCardTitle = "系统内置康复方案";
    var builtinRecoveryCardContent = "使用系统内置康复方案";
    var searchRecoveryCardTitle = "医生创建的康复方案";
    var searchRecoveryCardContent = "我有医生的康复方案编号";
    if (userInfo.role == 2) {
      builtinRecoveryCardTitle = "系统内置康复方案";
      builtinRecoveryCardContent = "查看系统内置康复方案";
      searchRecoveryCardTitle = "其他医生创建的康复方案";
      searchRecoveryCardContent = "搜索其他医生创建的康复方案";
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
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(builtinRecoveryCardTitle, style: cardTitleStyle,),
                        Expanded(child: Center(child: Text(
                          builtinRecoveryCardContent, style: cardHintStyle,))),
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
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(searchRecoveryCardTitle, style: cardTitleStyle,),
                        Expanded(child: Center(child: Text(
                          searchRecoveryCardContent, style: cardHintStyle,))),
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