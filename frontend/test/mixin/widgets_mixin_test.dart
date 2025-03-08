import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../TestBase.dart';

void main () {
  testWidgets("RequireLogin widgets mixin test", (WidgetTester tester) async {

  });

  testWidgets("UseCommonStyles widgets mixin test", (WidgetTester tester) async {
    TestBase.commonSetUp();

    TestBase.testWithFullGlobalStates(tester, UseCommonStylesTestWidget(), () async {
      var context = find.byType(UseCommonStylesTestWidget).evaluate().first;
      UseCommonStylesTestWidget widget = context.widget as UseCommonStylesTestWidget;
      var theme = Theme.of(context);
      var media = MediaQuery.of(context);

      TextStyle titleStyle = theme.textTheme.titleMedium!;
      TextStyle bodyStyle = theme.textTheme.bodyMedium!;
      TextStyle? hintTextStyle = theme.textTheme.displaySmall;

      if (media.size.height > 600) {
        titleStyle = theme.textTheme.titleLarge!;
        bodyStyle = theme.textTheme.bodyLarge!;
        hintTextStyle = theme.textTheme.displayMedium;
      }

      expect(widget.styles?.titleStyle, titleStyle);
      expect(widget.styles?.bodyStyle, bodyStyle);
      expect(widget.styles?.hintTextStyle, hintTextStyle);
    });
  });
}

class UseCommonStylesTestWidget extends StatelessWidget with UseCommonStyles {
  CommonStyles? styles;

  UseCommonStylesTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    styles = initStyles(context);
    return const Placeholder();
  }
}