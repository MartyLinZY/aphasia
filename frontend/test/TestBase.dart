
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/deprecated/global_states_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'fake_data.dart' as fake;

/// 主要功能：1. 进行一些通用Widget的声明。 2. 开启HttpClientManager的testMode。 3. 创建一些MockClient的通用stub method, 例如登录...等
class TestBase {
  static void _enableTestMode () {
    HttpClientManager().enableTestMode();
    var client = HttpClientManager().testClient!;
    AppSettings.testMode = true;

    // create some common mock http client method stub
    // login stub
    when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"identity": "${fake.identity}", "validateCode": "${fake.validateCode}"}'))
        .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.oldToken}"}', 200));
  }

  // final String placeholder = "";
  static Future<void> runTest(String description, Widget widget, AsyncValueSetter<WidgetTester> testBody) async {
    setUp(() {
      _enableTestMode();
    });

    testWidgets(description, (widgetTester) async {
      await widgetTester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          )
      );

      await testBody(widgetTester);
    });
  }

  static Future<void> runTestWithFullGlobalStates(String description, Widget widget, AsyncValueSetter<WidgetTester> testBody) async {
    setUp(() {
      _enableTestMode();
    });

    testWidgets(description, (widgetTester) async {
      await widgetTester.pumpWidget(
          GlobalStatesProviders(
            child: MaterialApp(
              home: Scaffold(
                body: widget,
              ),
            ),
          )
      );

      await testBody(widgetTester);
    });
  }

  // 新的通用测试函数，上面的测试函数会导致Android Studio无法单独运行单个测试用例
  static Future<void> testWithFullGlobalStates(WidgetTester tester, Widget widget, AsyncCallback testBody) async {
    await tester.pumpWidget(
        GlobalStatesProviders(
          child: MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        )
    );

    await testBody();
  }

  static void commonSetUp() {
    _enableTestMode();
  }
}