import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// #14b T8 单测。锁定 [ExamEditSelectionState] 三类行为：
/// 1. setter 幂等 + 写新值时单次 notifyListeners；
/// 2. `onCategoryDeleted` 三分支 + editSubCategoryIndex 残留语义；
/// 3. `onSubCategoryDeleted` 三分支（同 category 才调整、不同 category 不动），
///    其中"删 == editSubCategoryIndex 时清空"与"删 < editSubCategoryIndex 时下移"
///    两条是 T8 fix 后的正确行为；T5 commit 注释了原 prod 含 i/j 层级错位 + 缺
///    same-category 检查的两条 latent bug，本组用例即为 fix 的回归锁定。
void main() {
  // ExamEditSelectionState 的 setter 通过 `_safeNotify` 读
  // `SchedulerBinding.instance.schedulerPhase`，必须在 main 一进来就初始化
  // 测试 binding，否则 `instance` 抛 "Binding has not yet been initialized"。
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 计数 + 记录最后一次值的通用 listener helper。
  int Function() listenWith(ExamEditSelectionState s) {
    var count = 0;
    s.addListener(() {
      count++;
    });
    return () => count;
  }

  group("setter 幂等性 + notifyListeners 次数", () {
    test("editItem: 写 identical 同一对象不 fire", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      s.editItem = cat;
      var counter = listenWith(s);
      s.editItem = cat; // 同一 instance
      expect(counter(), 0);
    });

    test("editItem: 写 == 但非 identical 的另一对象会 fire（用 identical 判等）", () {
      var s = ExamEditSelectionState();
      var cat1 = QuestionCategory(description: "X");
      var cat2 = QuestionCategory(description: "X"); // 两个 instance
      s.editItem = cat1;
      var counter = listenWith(s);
      s.editItem = cat2;
      expect(counter(), 1);
      expect(identical(s.editItem, cat2), isTrue);
    });

    test("editItem: 写 null → null 不 fire（identical(null, null) == true）", () {
      var s = ExamEditSelectionState();
      var counter = listenWith(s);
      s.editItem = null;
      expect(counter(), 0);
    });

    test("editCategoryIndex: 同值不 fire，变更 fire 1 次", () {
      var s = ExamEditSelectionState();
      s.editCategoryIndex = 3;
      var counter = listenWith(s);
      s.editCategoryIndex = 3;
      expect(counter(), 0);
      s.editCategoryIndex = 4;
      expect(counter(), 1);
      s.editCategoryIndex = null;
      expect(counter(), 2);
    });

    test("editSubCategoryIndex / editQuestionIndex: 同值不 fire", () {
      var s = ExamEditSelectionState();
      s.editSubCategoryIndex = 2;
      s.editQuestionIndex = 5;
      var counter = listenWith(s);
      s.editSubCategoryIndex = 2;
      s.editQuestionIndex = 5;
      expect(counter(), 0);
    });

    test("editingItem: false → false 不 fire，false → true fire 1 次", () {
      var s = ExamEditSelectionState();
      var counter = listenWith(s);
      s.editingItem = false;
      expect(counter(), 0);
      s.editingItem = true;
      expect(counter(), 1);
      s.editingItem = true;
      expect(counter(), 1);
    });
  });

  group("onCategoryDeleted", () {
    test("editItem 不是 QuestionCategory（null）→ 字段全部不变，只 notify 1 次", () {
      var s = ExamEditSelectionState();
      // editItem == null 默认
      var counter = listenWith(s);
      s.onCategoryDeleted(0);
      expect(s.editItem, isNull);
      expect(s.editCategoryIndex, isNull);
      expect(s.editingItem, isFalse);
      expect(counter(), 1);
    });

    test("editItem 是 QuestionSubCategory → 字段不变", () {
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 1;
      s.editSubCategoryIndex = 0;
      s.editingItem = true;
      s.onCategoryDeleted(1);
      expect(identical(s.editItem, sub), isTrue);
      expect(s.editCategoryIndex, 1);
      expect(s.editSubCategoryIndex, 0);
      expect(s.editingItem, isTrue);
    });

    test("editing 被删的 category → 清空 editItem / editCategoryIndex / editingItem", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      s.editItem = cat;
      s.editCategoryIndex = 2;
      s.editingItem = true;
      s.onCategoryDeleted(2);
      expect(s.editItem, isNull);
      expect(s.editCategoryIndex, isNull);
      expect(s.editingItem, isFalse);
    });

    test("editing 在被删 category 之后 → 下移 editCategoryIndex", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      s.editItem = cat;
      s.editCategoryIndex = 3;
      s.editingItem = true;
      s.onCategoryDeleted(1);
      expect(identical(s.editItem, cat), isTrue);
      expect(s.editCategoryIndex, 2); // 3 → 2
      expect(s.editingItem, isTrue); // 不重置
    });

    test("editing 在被删 category 之前 → editCategoryIndex 不变", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      s.editItem = cat;
      s.editCategoryIndex = 0;
      s.editingItem = true;
      s.onCategoryDeleted(3);
      expect(identical(s.editItem, cat), isTrue);
      expect(s.editCategoryIndex, 0);
    });

    test("锁定历史细节：清空 editItem 时 editSubCategoryIndex 残留不动", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      // 先停在 subCategory，再切到 category（editSubCategoryIndex 没被业务清理）
      s.editSubCategoryIndex = 7;
      s.editItem = cat;
      s.editCategoryIndex = 1;
      s.onCategoryDeleted(1);
      // editItem / editCategoryIndex 被清，但 editSubCategoryIndex 仍为 7
      expect(s.editItem, isNull);
      expect(s.editCategoryIndex, isNull);
      expect(s.editSubCategoryIndex, 7);
    });
  });

  group("onSubCategoryDeleted（T8 fix 后）", () {
    test("editItem 不是 QuestionSubCategory → 字段不变", () {
      var s = ExamEditSelectionState();
      var cat = QuestionCategory(description: "X");
      s.editItem = cat;
      s.editCategoryIndex = 0;
      s.editingItem = true;
      s.onSubCategoryDeleted(0, 0);
      expect(identical(s.editItem, cat), isTrue);
      expect(s.editCategoryIndex, 0);
      expect(s.editingItem, isTrue);
    });

    test("同 category，删的就是当前 editSubCategoryIndex → 清空所有", () {
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 2;
      s.editSubCategoryIndex = 3;
      s.editingItem = true;
      s.onSubCategoryDeleted(2, 3);
      expect(s.editItem, isNull);
      expect(s.editCategoryIndex, isNull);
      expect(s.editSubCategoryIndex, isNull);
      expect(s.editingItem, isFalse);
    });

    test("同 category，editing 在被删 subCategory 之后 → 下移 editSubCategoryIndex", () {
      // T8 fix 核心：原 prod 写 `editSubCategoryIndex! > categoryIndex`
      // （比 categoryIndex 而非 subCategoryIndex），层级错位。本用例锁定 fix。
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 0; // 故意让 categoryIndex < subCategoryIndex，
      s.editSubCategoryIndex = 5; // 让原 buggy 写法巧合"正确"也变得不可能
      s.editingItem = true;
      s.onSubCategoryDeleted(0, 2);
      expect(identical(s.editItem, sub), isTrue);
      expect(s.editCategoryIndex, 0);
      expect(s.editSubCategoryIndex, 4); // 5 → 4
      expect(s.editingItem, isTrue);
    });

    test("同 category，editing 在被删 subCategory 之前 → editSubCategoryIndex 不变", () {
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 1;
      s.editSubCategoryIndex = 0;
      s.onSubCategoryDeleted(1, 3);
      expect(identical(s.editItem, sub), isTrue);
      expect(s.editSubCategoryIndex, 0);
    });

    test("不同 category → editSubCategoryIndex 完全不变（同值 == 也不能误判清空）", () {
      // T8 fix 第二条核心：补 same-category 检查。原 prod 不检查 categoryIndex，
      // 删 categoryB.subCategory[3] 时如果当前编辑 categoryA.subCategory[3]
      // 会被误清空。
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 2;
      s.editSubCategoryIndex = 3;
      s.editingItem = true;
      s.onSubCategoryDeleted(5, 3); // 不同 category，相同 subCategoryIndex
      expect(identical(s.editItem, sub), isTrue);
      expect(s.editCategoryIndex, 2);
      expect(s.editSubCategoryIndex, 3);
      expect(s.editingItem, isTrue);
    });

    test("不同 category，且 deleted subCategoryIndex < editSubCategoryIndex → 也不下移", () {
      // 也由 same-category 检查覆盖：不同 category 的索引彼此独立。
      var s = ExamEditSelectionState();
      var sub = QuestionSubCategory(description: "a");
      s.editItem = sub;
      s.editCategoryIndex = 0;
      s.editSubCategoryIndex = 5;
      s.onSubCategoryDeleted(7, 2);
      expect(s.editSubCategoryIndex, 5);
    });
  });
}
