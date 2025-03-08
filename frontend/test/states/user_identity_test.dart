import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';

import '../fake_data.dart' as fake;

void main() {
  test('UserIdentity smoke test', () async {
    HttpClientManager manager = HttpClientManager();
    manager.enableTestMode();
    final client = manager.testClient!;

    final logs = <String>[];

    // authenticate without token
    UserIdentity? ret = await UserIdentity.authWithToken();
    expect(ret, null);

    // authenticate with old token success
    // logs.clear();
    // model = UserIdentity(token: fake.oldToken);
    // listener1 () {
    //   logs.add("authWithToken");
    // }
    // model.addListener(listener1);
    // when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"token": "${fake.oldToken}"}'))
    //     .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.token}"}', 200));
    //
    // expect(await model.authWithToken(), true);
    // expect(logs, ["authWithToken"]);
    // expect(model.uid, fake.uid);
    // expect(model.token, fake.token);
    // model.removeListener(listener1);
    //
    // // authenticate with old token fail
    // when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"token": "${fake.token}"}'))
    //     .thenAnswer((realInvocation) async => Response('', 403));
    // expect(await model.authWithToken(), false);

    // login
    when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"identity": "${fake.identity}", "validateCode": "${fake.validateCode}"}'))
        .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.oldToken}", "role": 1, "identity": "${fake.identity}"', 200));
    final i = await UserIdentity.login(identity: fake.identity, password: fake.validateCode);
    expect(i?.identity, fake.identity);
    expect(i?.uid, fake.uid);
    expect(i?.token, fake.oldToken);
  });
}