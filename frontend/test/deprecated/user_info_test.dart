import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('UserIdentity smoke test', () async {
    var model = UserInfo();
    expect(model.role, null);
    expect(model.name, null);

    model.role = 1;
    model.role = 1;

    var logs = <String>[];
    listener() {
      logs.add(model.role.toString());
    }
    model.addListener(listener);
    model.role = 1;
    model.removeListener(listener);

    listener1() {
      logs.add(model.name!);
    }
    model.addListener(listener1);
    model.name = "新名称";
    model.removeListener(listener1);
    expect(logs, ["1", "新名称"]);
  });
}