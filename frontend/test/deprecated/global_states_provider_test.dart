import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/deprecated/global_states_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../TestBase.dart';

void main() {
  TestBase.runTest('GlobalStateProvider smoke test', const GlobalStatesProviders(
      child: Text("Test Stub")
  ), (WidgetTester tester) async {
    expect(find.byType(GlobalStatesProviders), findsOneWidget);

    expect(find.text("Test Stub").evaluate().first.read<UserIdentity>().runtimeType, UserIdentity);
    expect(
        find.ancestor(
            of: find.text("Test Stub"),
            matching: find.byType(ChangeNotifierProvider<UserIdentity>)
        ), findsOneWidget
    );

    // Code below needs adding ChangeNotifier<> in GlobalStatesProvider
    // expect(find.text("Test Stub").evaluate().first.read<StubNotifier>().runtimeType, StubNotifier);
    // expect(
    //     find.ancestor(
    //         of: find.text("Test Stub"),
    //         matching: find.byType(ChangeNotifierProvider<StubNotifier>)
    //     ), findsOneWidget
    // );
    //
    // expect(find.text("Test Stub").evaluate().first.read<StubNotifier1>().runtimeType, StubNotifier1);
    // expect(
    //     find.ancestor(
    //         of: find.text("Test Stub"),
    //         matching: find.byType(ChangeNotifierProvider<StubNotifier1>)
    //     ), findsOneWidget
    // );
    // var contextGetter = find.byType(ContextGetter);
    // expect(contextGetter, findsOneWidget);
  });
}

class TestNotifier extends ChangeNotifier {}
class TestNotifier1 extends ChangeNotifier {}