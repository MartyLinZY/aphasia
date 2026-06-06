import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_question_edit.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/question_edit_steps/question_edit_form_widgets.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/question_edit_steps/question_type_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../TestBase.dart';

/// 把 DoctorExamQuestionEditPage 挂到 MaterialApp 下；可选传入预置 [question]。
///
/// 本组测试不涉及 HTTP（不点 "创建" / "保存" 触发 Question.updateQuestion），
/// 所以只要 shared_pref + testClient 三件套到位就足够。
Widget _wrapPage({Question? question}) {
  return MaterialApp(
    home: DoctorExamQuestionEditPage(question: question),
  );
}

void main() {
  TestBase.commonSetUp();

  // 状态隔离三件套（同 doctor_all_exams_test 等）。
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WrappedSharedPref.instance = null;
    HttpClientManager().testClient = null;
    TestBase.commonSetUp();
  });

  // Phase 1+2 把 1292→766 行拆出 3 个子 widget（QuestionTypeStep /
  // HintRuleStep / question_edit_form_widgets），但页面本身一直无 widget
  // test。本文件按 #14b 风格补回归覆盖，锁拆出的 3 个子 widget 在 Stepper
  // 各步骤的渲染契约。

  testWidgets("Step 1: 默认渲染 QuestionTypeStep + AudioQuestion 题型简介",
      (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pumpAndSettle();

    expect(find.byType(DoctorExamQuestionEditPage), findsOneWidget);
    expect(find.byType(QuestionTypeStep), findsOneWidget);

    // AppBar 标题：无 question 入参时为"创建新题目"
    expect(find.text("创建新题目"), findsOneWidget);

    // QuestionTypeStep 内的固定文案
    expect(find.text("选择题目类型："), findsOneWidget);
    expect(find.text("题目类型："), findsOneWidget);

    // AudioQuestion 简介——_questionIntroduction[AudioQuestion] 的前缀
    expect(
      find.textContaining("录音作答题：患者通过录音作答"),
      findsOneWidget,
    );
  });

  testWidgets("Step 1 → Step 2: 点'下一步'切到 BasicInfoStep（默认 AudioQuestion 无校验阻塞）",
      (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pumpAndSettle();

    // Step 1 → 2 的 validateAndApplyChangesBeforeStepChange 在 currStep!=1&&!=2
    // 时直接 return true，所以默认 AudioQuestion 无需填表即可跳。
    await tester.tap(find.widgetWithText(ElevatedButton, "下一步"));
    await tester.pumpAndSettle();

    // QuestionTypeStep 应消失（Stepper.type=horizontal 只渲染当前 step 的
    // content）。Step 2 用 DecoratedTextField 渲基本信息表单，label="题目名称："
    // 与 label="题干文本："是稳定锚点。
    expect(find.byType(QuestionTypeStep), findsNothing);
    expect(find.byType(DecoratedTextField), findsNWidgets(2)); // 题目名称 + 题干文本
    expect(find.text("题目名称："), findsOneWidget);
    expect(find.text("题干文本："), findsOneWidget);

    // 两个 MediaSection（题干音频 / 题干图片）
    expect(find.byType(MediaSection), findsNWidgets(2));
    expect(find.text("题干音频设置"), findsOneWidget);
    expect(find.text("题干图片设置"), findsOneWidget);
  });

  testWidgets(
      "Step 2: 传入带 imageUrl 的 Question → ImageOmitTimeField 应可见 + 提示文案",
      (tester) async {
    final q = AudioQuestion()
      ..imageUrl = "assets/images/for_question_setting/cup.jpg"
      ..omitImageAfterSeconds = 5;

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();

    // 编辑模式下 AppBar 标题切换
    expect(find.text("编辑题目"), findsOneWidget);

    // Step 1 → 2
    await tester.tap(find.widgetWithText(ElevatedButton, "下一步"));
    await tester.pumpAndSettle();

    // ImageOmitTimeField 因 currQuestion.imageUrl != null 走 Visibility=true
    // 分支，"图片展示时间（秒）：" + 提示前缀都应出现
    expect(find.byType(ImageOmitTimeField), findsOneWidget);
    expect(find.text("图片展示时间（秒）："), findsOneWidget);
    expect(
      find.textContaining("场景寻物题设为-1保持显示"),
      findsOneWidget,
    );
  });

  testWidgets(
      "Step 2: 点 '清除' 图片 → confirm dialog → 确认 → ImageOmitTimeField 隐藏",
      (tester) async {
    final q = AudioQuestion()
      ..imageUrl = "assets/images/for_question_setting/cup.jpg"
      ..omitImageAfterSeconds = 5;

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, "下一步"));
    await tester.pumpAndSettle();

    // 前置：ImageOmitTimeField 此刻可见
    expect(find.byType(ImageOmitTimeField), findsOneWidget);

    // MediaSection 内 "清除" 是 _MediaButton（Tooltip + TextButton.icon），
    // 按 byTooltip 比按 text 稳——Tooltip.message 是显式 prop 绑定。
    // ensureVisible 防止 Stepper 内容超出 viewport 时 tap 落不到。
    final clearBtn = find.byTooltip("清除");
    expect(clearBtn, findsOneWidget);
    await tester.ensureVisible(clearBtn);
    await tester.pumpAndSettle();
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // confirm dialog 弹起："确认要删除已经设置的图片吗？" + 取消 / 确认
    // 按钮（buildSimpleActionDialog 用 ElevatedButton）
    expect(find.text("确认要删除已经设置的图片吗？"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "确认"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
    await tester.pumpAndSettle();

    // _handleClearImage 把 currQuestion.imageUrl = null → ImageOmitTimeField
    // 的 Visibility.visible=false → 子树隐藏，"图片展示时间（秒）：" 也跟着消失
    // （ImageOmitTimeField widget 本身仍 mount，但子树不渲——所以只锁
    // 文案而非 widget 类型 absent）
    expect(find.text("图片展示时间（秒）："), findsNothing);
    expect(
      find.textContaining("场景寻物题设为-1保持显示"),
      findsNothing,
    );
  });

  // 本文件其余 step 覆盖（Step 4 HintRuleStep 表格 + 删除）在后续 commit
  // 增量补充。
}
