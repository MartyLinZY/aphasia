import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_question_edit.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_question_rule_edit.dart';
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

    expect(find.text("确认要删除已经设置的图片吗？"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
    await tester.pumpAndSettle();

    // confirm helper 修完之后只 caller 自己 pop 一次——page 仍活着
    // （sanity 断言：原本双 pop bug 时这里会 findsNothing 把整页弹掉）。
    expect(find.byType(DoctorExamQuestionEditPage), findsOneWidget);
    // _handleClearImage 把 currQuestion.imageUrl = null + setState →
    // ImageOmitTimeField 子树 Visibility.visible=false → 文案消失
    expect(find.text("确认要删除已经设置的图片吗？"), findsNothing);
    expect(find.text("图片展示时间（秒）："), findsNothing);
    expect(
      find.textContaining("场景寻物题设为-1保持显示"),
      findsNothing,
    );
  });

  /// 构造一份能一路过 4 步 Stepper 验证的 AudioQuestion——
  /// Step 2 校验要求 questionText!="" 或 audioUrl!=null（满足 questionText）；
  /// Step 3 校验走 evalRule.checkSetting() → super.checkSetting() 要求
  /// conditions 非空（[condCount] 默认 1，因为
  /// doctor_exam_question_rule_edit.dart:695 渲染时会读 ranges[0]，缺会
  /// RangeError；condCount 调大用于覆盖 Step 3 删除 EvalCondition 路径）。
  /// hintRules 预置 [hintCount] 条用于 Step 4 表格回归。
  AudioQuestion buildNavigableAudioQuestion(
      {int hintCount = 0, int condCount = 1}) {
    final q = AudioQuestion()
      ..alias = "测试题"
      ..questionText = "题干文本";
    for (var i = 0; i < condCount; i++) {
      q.evalRule!.addEvalCondition(
          EvalCondition(score: (10 * (i + 1)).toDouble())..addRange(i, i + 1));
    }
    for (var i = 0; i < hintCount; i++) {
      q.evalRule!.addHintRule(HintRule(
        hintText: "提示${i + 1}",
        scoreLowBound: 0,
        scoreHighBound: 5,
      ));
    }
    return q;
  }

  /// 共用：连续点 [count] 次 "下一步"，每步 ensureVisible 兜底。
  /// Step 1→3 传 2，Step 1→4 传 3。
  Future<void> goNextSteps(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      final btn = find.widgetWithText(ElevatedButton, "下一步");
      expect(btn, findsOneWidget, reason: "下一步 button missing at iter $i");
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();
    }
  }

  /// Step 1 → 4 三次"下一步"，兼容旧调用。
  Future<void> goToHintRuleStep(WidgetTester tester) => goNextSteps(tester, 3);

  // ====== Step 3: EvalRuleStep（评分规则）======
  // Step 3 = "评分规则"，主体是 DoctorExamQuestionRuleEditSubPage（785 行）。
  // L1 锁默认渲染契约（题头 + 通用三输入 + DropdownMenu + 得分条件表格 + 新增
  // 按钮 + 表格头随 evalRule.getScoreConditionName 动态拼前缀），L2 锁删除路径
  // 走 confirm helper 的回归（caller 单 pop / page 仍活，对标 Step 4 删 hintRule
  // 的双套路）。L3 增改 EvalCondition 走嵌套 QuestionScoreConditionEditDialog +
  // 跨题型 dropdown 切换分支爆炸，暂不覆盖。
  //
  // 关于 viewport：Step 3 内容 ≥ Step 4（同 400 高 Table，外加 3 个 input field +
  // dropdown），保持 1600x1200 surface；个别测试需要 ensureVisible 触到目标控件。

  testWidgets(
      "Step 3: 默认渲染 DoctorExamQuestionRuleEditSubPage（通用三输入 + 得分条件表 + 表头按 evalRule 动态拼）",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 默认 condCount=1 即可，本测试只看渲染骨架
    final q = buildNavigableAudioQuestion();

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goNextSteps(tester, 2);

    // Step 3 子页本体
    expect(find.byType(DoctorExamQuestionRuleEditSubPage), findsOneWidget);

    // Step 3 自身（_buildThirdStep）的 header 与 DropdownMenu label
    expect(find.text("评分规则设置"), findsOneWidget);
    expect(find.text("评分规则："), findsOneWidget);

    // 通用三输入 field label（_buildEvalRuleSetting 顶部固定三条）
    expect(find.text("题目满分："), findsOneWidget);
    expect(find.text("题目默认得分："), findsOneWidget);
    expect(find.text("答题限时（秒）："), findsOneWidget);

    // 得分条件区
    expect(find.text("得分条件列表："), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "新增得分条件"), findsOneWidget);

    // 表头 8 列。"序号" 与 Step 4 的 HintRule 表头同名——但本测试只到 Step 3，
    // Step 4 未渲，所以单数即可命中。"下界"/"上界" 加 evalRule
    // getScoreConditionName() 前缀；AudioQuestion 默认 evalRule
    // EvalAudioQuestionByKeywordsMatchesCount.getScoreConditionName 返
    // "关键词正确个数"，因此表头是 "关键词正确个数下界"/"关键词正确个数上界"。
    expect(find.text("序号"), findsOneWidget);
    expect(find.text("对应得分"), findsOneWidget);
    expect(find.text("关键词正确个数下界"), findsOneWidget);
    expect(find.text("关键词正确个数上界"), findsOneWidget);
    expect(find.text("作答时间下界"), findsOneWidget);
    expect(find.text("作答时间上界"), findsOneWidget);
    expect(find.text("经过提示"), findsOneWidget);
    expect(find.text("操作"), findsOneWidget);

    // 预置 1 条 EvalCondition → 表格 1 行行操作 4 个 tooltip：编辑/删除/上移/下移
    expect(find.byTooltip("编辑"), findsOneWidget);
    expect(find.byTooltip("删除"), findsOneWidget);
    expect(find.byTooltip("上移"), findsOneWidget);
    expect(find.byTooltip("下移"), findsOneWidget);
  });

  testWidgets(
      "Step 3: 删除第一条 EvalCondition → confirm → 表格只剩 1 行（confirm helper 单 pop 回归）",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(condCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goNextSteps(tester, 2);

    // 前置：2 条 EvalCondition → 2 个删除 Tooltip
    final deleteBtns = find.byTooltip("删除");
    expect(deleteBtns, findsNWidgets(2));
    await tester.ensureVisible(deleteBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtns.first);
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该得分规则吗？"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
    await tester.pumpAndSettle();

    // confirm helper 修完 page 仍活着（双 pop bug 时这里会 findsNothing
    // 把整页弹掉）；rule.deleteEvalCondition 走完，删除按钮只剩 1 个。
    expect(find.byType(DoctorExamQuestionEditPage), findsOneWidget);
    expect(find.byType(DoctorExamQuestionRuleEditSubPage), findsOneWidget);
    expect(find.text("确认要删除该得分规则吗？"), findsNothing);
    expect(find.byTooltip("删除"), findsOneWidget);
  });

  testWidgets(
      "Step 3: 删除 EvalCondition → 取消 → dialog 关、2 条 EvalCondition 保留",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(condCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goNextSteps(tester, 2);

    final deleteBtns = find.byTooltip("删除");
    expect(deleteBtns, findsNWidgets(2));
    await tester.ensureVisible(deleteBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtns.first);
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该得分规则吗？"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "取消"));
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该得分规则吗？"), findsNothing);
    expect(find.byType(DoctorExamQuestionRuleEditSubPage), findsOneWidget);
    expect(find.byTooltip("删除"), findsNWidgets(2));
  });

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

  testWidgets(
      "Step 4: 删除第一条 hintRule → confirm → 表格只剩 1 行",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(hintCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goToHintRuleStep(tester);

    // 前置：2 条 hintRule → 2 个删除 Tooltip
    final deleteBtns = find.byTooltip("删除");
    expect(deleteBtns, findsNWidgets(2));
    await tester.ensureVisible(deleteBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtns.first);
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该提示规则吗？"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
    await tester.pumpAndSettle();

    // confirm helper 修完 page 仍活着；只 caller 自己的 deleteHintRule
    // 单 pop 走完——表格只剩 1 条 hintRule。
    expect(find.byType(DoctorExamQuestionEditPage), findsOneWidget);
    expect(find.byType(HintRuleStep), findsOneWidget);
    expect(find.text("确认要删除该提示规则吗？"), findsNothing);
    expect(find.byTooltip("删除"), findsOneWidget);
  });

  testWidgets(
      "Step 4: 点删除 → 取消 → dialog 关、2 条 hintRule 保留",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final q = buildNavigableAudioQuestion(hintCount: 2);

    await tester.pumpWidget(_wrapPage(question: q));
    await tester.pumpAndSettle();
    await goToHintRuleStep(tester);

    final deleteBtns = find.byTooltip("删除");
    expect(deleteBtns, findsNWidgets(2));
    await tester.ensureVisible(deleteBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtns.first);
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该提示规则吗？"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "取消"));
    await tester.pumpAndSettle();

    expect(find.text("确认要删除该提示规则吗？"), findsNothing);
    expect(find.byType(HintRuleStep), findsOneWidget);
    expect(find.byTooltip("删除"), findsNWidgets(2));
  });
}
