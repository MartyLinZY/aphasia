import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_question_edit.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/question_edit_steps/hint_rule_step.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/question_edit_steps/question_edit_form_widgets.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/question_edit_steps/question_type_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../TestBase.dart';

/// 把 DoctorExamQuestionEditPage 挂到 MaterialApp 下，并在它下面铺一个
/// 占位 base 路由作缓冲。
///
/// 原因：prod 用的 confirm 辅助函数（utils/common_widget_function.dart:25）
/// 在 onConfirm 回调里被 caller 主动 Navigator.pop(context) 关 dialog 之后，
/// helper 自己又会跑一次 Navigator.pop(context, true)——这个二次 pop 在
/// 测试环境里会顺手把 home route 也弹掉，导致整个 DoctorExamQuestionEditPage
/// 被卸载、屏上空白。在 home 下面铺一个 base scaffold 让这次 pop 落到
/// base 而不是 nothing，DoctorExamQuestionEditPage 仍在路由栈顶。
///
/// 本组测试不涉及 HTTP（不点 "创建" / "保存" 触发 Question.updateQuestion），
/// 所以只要 shared_pref + testClient 三件套到位就足够。
Widget _wrapPage({Question? question}) {
  return MaterialApp(
    home: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
            body: Center(child: Text("__base_route__"))),
      ),
      onGenerateInitialRoutes: (state, initialRoute) {
        return [
          MaterialPageRoute(
              builder: (_) => const Scaffold(
                  body: Center(child: Text("__base_route__")))),
          MaterialPageRoute(
              builder: (_) =>
                  DoctorExamQuestionEditPage(question: question)),
        ];
      },
    ),
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

  // 注：清除图片的 "确认" 路径无法在 widget test 里走通——confirm helper
  // （utils/common_widget_function.dart:25）在 onConfirm 后跑第二次
  // Navigator.pop(context, true)，加上 caller _handleClearImage 自己也
  // Navigator.pop(dialog) 一次，双 pop 会把 DoctorExamQuestionEditPage
  // 也弹掉、屏空白，断言 findsNothing 全变 false positive（已实测）。
  // 真实 app 因为外层路由通常压了多个 route 才被掩盖。
  // 这里只覆盖 "弹 dialog → 取消" 的单 pop 路径，锁住按钮 → dialog 的
  // 路由契约，不深入 clear 的 setState。confirm 路径的真覆盖需先修
  // prod 的双 pop bug，单独立项。
  testWidgets(
      "Step 2: 点 '清除' 图片 → 弹 confirm dialog → 取消 → 图片仍设置",
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

    // confirm dialog 弹起："确认要删除已经设置的图片吗？" + 取消 / 确认 按钮
    expect(find.text("确认要删除已经设置的图片吗？"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "取消"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "确认"), findsOneWidget);

    // 取消：单 pop 路径，page 仍活着，ImageOmitTimeField 仍可见
    await tester.tap(find.widgetWithText(ElevatedButton, "取消"));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorExamQuestionEditPage), findsOneWidget);
    expect(find.text("确认要删除已经设置的图片吗？"), findsNothing);
    expect(find.byType(ImageOmitTimeField), findsOneWidget);
    expect(find.text("图片展示时间（秒）："), findsOneWidget);
  });

  /// 构造一份能一路过 4 步 Stepper 验证的 AudioQuestion——
  /// Step 2 校验要求 questionText!="" 或 audioUrl!=null（满足 questionText）；
  /// Step 3 校验走 evalRule.checkSetting() → super.checkSetting() 要求
  /// conditions 非空（预置一个 EvalCondition + 一条 range，因为
  /// doctor_exam_question_rule_edit.dart:695 渲染时会读 ranges[0]，缺会
  /// RangeError）。hintRules 预置 [count] 条用于 Step 4 表格回归。
  AudioQuestion buildNavigableAudioQuestion({int hintCount = 0}) {
    final q = AudioQuestion()
      ..alias = "测试题"
      ..questionText = "题干文本";
    q.evalRule!.addEvalCondition(
        EvalCondition(score: 10)..addRange(1, 1));
    for (var i = 0; i < hintCount; i++) {
      q.evalRule!.addHintRule(HintRule(
        hintText: "提示${i + 1}",
        scoreLowBound: 0,
        scoreHighBound: 5,
      ));
    }
    return q;
  }

  /// Step 1 → 4 三次"下一步"。Stepper 内容较高时按钮容易越出 viewport，
  /// 用 ensureVisible 兜底；并 expect 每次点击前 "下一步" 确实存在。
  Future<void> goToHintRuleStep(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      final btn = find.widgetWithText(ElevatedButton, "下一步");
      expect(btn, findsOneWidget, reason: "下一步 button missing at iter $i");
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
      "Step 4: 传入 2 条 hintRules → HintRuleStep 表格渲 2 行 + '新增提示条件' 按钮",
      (tester) async {
    // Step 4 含一个 400 高度的 Table，默认 800x600 surface 会让 Stepper
    // 内容空间不足触发 RangeError，把 surface 拉大。
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(hintCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goToHintRuleStep(tester);

    expect(find.byType(HintRuleStep), findsOneWidget);

    // 表头 + "新增提示条件" 按钮
    expect(find.text("序号"), findsOneWidget);
    expect(find.text("触发提示得分下界"), findsOneWidget);
    expect(find.text("触发提示得分上界"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "新增提示条件"), findsOneWidget);

    // 两条 hintRule 的序号 1 / 2。注意 Stepper.horizontal 的 step icon
    // 也是 1/2/3/4 数字 Text，得 scope 到 HintRuleStep 子树才不冲突。
    final hintStep = find.byType(HintRuleStep);
    expect(
      find.descendant(of: hintStep, matching: find.text("1")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hintStep, matching: find.text("2")),
      findsOneWidget,
    );
  });

  // 删除二次确认路径有一条 prod 隐患：utils/common_widget_function.dart:25
  // 的 confirm helper 在 onConfirm 触发后会跑一次 Navigator.pop(context, true)，
  // 而 caller（HintRuleStep / _handleClearImage 等）的 onConfirm 内部又会
  // 主动 Navigator.pop(context) 关 dialog——双 pop 在测试 Navigator 路由栈
  // 仅 [home] 的场景下会把整个 DoctorExamQuestionEditPage 也弹掉，屏上空白。
  // 真实 app 因为外层路由通常压了多个 route 才被掩盖。本 commit 不修 prod，
  // 只覆盖 "取消" 路径——它走 onCancel + 仅 helper 的单 pop（caller 没传
  // onCancel 时 user-callback 是 noop），不触发双 pop。
  testWidgets(
      "Step 4: 点删除 → 弹 confirm dialog → 取消 → dialog 关闭、2 条 hintRule 保留",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(hintCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goToHintRuleStep(tester);

    // 两行 hintRule → 2 个删除 Tooltip
    final deleteBtns = find.byTooltip("删除");
    expect(deleteBtns, findsNWidgets(2));
    await tester.ensureVisible(deleteBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtns.first);
    await tester.pumpAndSettle();

    // confirm dialog
    expect(find.text("确认要删除该提示规则吗？"), findsOneWidget);

    // 取消（buildSimpleActionDialog 的 "取消" 是 ElevatedButton）
    await tester.tap(find.widgetWithText(ElevatedButton, "取消"));
    await tester.pumpAndSettle();

    // dialog 关闭，page 仍活着，hintRules 仍 2 条
    expect(find.text("确认要删除该提示规则吗？"), findsNothing);
    expect(find.byType(HintRuleStep), findsOneWidget);
    expect(find.byTooltip("删除"), findsNWidgets(2));
  });
}
