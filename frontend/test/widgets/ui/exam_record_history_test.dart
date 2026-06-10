import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/widgets/ui/patient/exam_record_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../TestBase.dart';

void main() {
  // ExamRecordHistoryPage 通过 `context.watch<SingleModelState<UserIdentity>>()`
  // 读身份，build 时取 `model!.uid` 发后端查询；prod 在 my_app.dart 顶部 wrap
  // 该 Provider，测试需补齐并塞入一个非空 UserIdentity。
  TestBase.runTestWithFullGlobalStates(
      'RecoveryEntryPage smoke test',
      ChangeNotifierProvider<SingleModelState<UserIdentity>>(
        create: (_) => SingleModelState<UserIdentity>(
            UserIdentity(identity: "patient", uid: "1", token: "fake", role: 1)),
        child: const ExamRecordHistoryPage(commonStyles: null),
      ),
      (WidgetTester tester) async {});
}