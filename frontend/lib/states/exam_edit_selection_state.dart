import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 套题编辑页面的"当前选中/编辑项"状态。
///
/// 承载原本散落在父 State 上的 4 个 selection 字段（`editItem` /
/// `editCategoryIndex` / `editSubCategoryIndex` / `editingItem`），以及暂存的
/// `editQuestionIndex`。
///
/// 父 State (`_DoctorExamEditPageState`) 持有 instance 并通过
/// `ChangeNotifierProvider.value` 暴露给整棵子树；子页与左栏 3 个 widget
/// (`ExamCategoryList` / `SubCategoryList` / `QuestionList`) 都通过
/// `context.read` 或 `context.watch` 读写。
///
/// 业务方法 `onCategoryDeleted` / `onSubCategoryDeleted` 用于删除后调整选中
/// 索引——历史上散落在父 setState 内联块里，#14b 集中到此处后由单元测试
/// 锁定行为。
class ExamEditSelectionState extends ChangeNotifier {
  dynamic _editItem;
  int? _editCategoryIndex;
  int? _editSubCategoryIndex;
  int? _editQuestionIndex;
  bool _editingItem = false;

  dynamic get editItem => _editItem;
  int? get editCategoryIndex => _editCategoryIndex;
  int? get editSubCategoryIndex => _editSubCategoryIndex;
  int? get editQuestionIndex => _editQuestionIndex;
  bool get editingItem => _editingItem;

  set editItem(dynamic v) {
    if (identical(_editItem, v)) return;
    _editItem = v;
    _safeNotify();
  }

  set editCategoryIndex(int? v) {
    if (_editCategoryIndex == v) return;
    _editCategoryIndex = v;
    _safeNotify();
  }

  set editSubCategoryIndex(int? v) {
    if (_editSubCategoryIndex == v) return;
    _editSubCategoryIndex = v;
    _safeNotify();
  }

  set editQuestionIndex(int? v) {
    if (_editQuestionIndex == v) return;
    _editQuestionIndex = v;
    _safeNotify();
  }

  set editingItem(bool v) {
    if (_editingItem == v) return;
    _editingItem = v;
    _safeNotify();
  }

  /// 当某个 category 被删除时调用，调整当前 selection 字段。
  ///
  /// 仅当：当前正在编辑某个 category 时才需调整——若编辑的就是被删那一项
  /// 则清空 (editItem / editCategoryIndex / editingItem)；若编辑的是被删项
  /// 之后的 category 则下移 editCategoryIndex。
  ///
  /// 注意：方法**不会清理** `editSubCategoryIndex` 的残留。这条历史细节
  /// 在 `_buildActionArea` 当前路由逻辑下是无害的——editItem == null 时
  /// `_buildActionArea` 直接返回空，永远不会读 editSubCategoryIndex；下次
  /// 用户进入某 subCategory 编辑也会覆盖之。单测中显式锁定此行为。
  void onCategoryDeleted(int categoryIndex) {
    if (_editItem.runtimeType == QuestionCategory) {
      assert(_editCategoryIndex != null);
      if (_editCategoryIndex == categoryIndex) {
        _editItem = null;
        _editCategoryIndex = null;
        _editingItem = false;
      } else if (_editCategoryIndex! > categoryIndex) {
        _editCategoryIndex = _editCategoryIndex! - 1;
      }
    }
    _safeNotify();
  }

  /// 当某个 subCategory 被删除时调用，调整当前 selection 字段。
  ///
  /// 仅当：当前正在编辑某个 subCategory，且**属于同一 category** 时，才需
  /// 调整索引——若编辑的就是被删那一项则清空；若编辑的是被删项之后的同
  /// category 子项则下移。**不同 category 的 subCategory 索引互相独立，
  /// 不能跨 category 比较 / 调整。**
  ///
  /// T5 阶段曾把原 `_buildQuestionTile` 中"删除子项"分支的 setState 内联块
  /// 逐字迁过来，含两条历史 prod 缺陷：① 没检查 `editCategoryIndex ==
  /// categoryIndex`，跨 category 误清空；② 用 `editSubCategoryIndex! >
  /// categoryIndex` 比较，层级错位（应比 subCategoryIndex）。T8 一并 fix
  /// 并补单测锁定正确行为。
  void onSubCategoryDeleted(int categoryIndex, int subCategoryIndex) {
    if (_editItem.runtimeType == QuestionSubCategory &&
        _editCategoryIndex == categoryIndex) {
      assert(_editSubCategoryIndex != null);
      if (_editSubCategoryIndex == subCategoryIndex) {
        _editItem = null;
        _editCategoryIndex = null;
        _editSubCategoryIndex = null;
        _editingItem = false;
      } else if (_editSubCategoryIndex! > subCategoryIndex) {
        _editSubCategoryIndex = _editSubCategoryIndex! - 1;
      }
    }
    _safeNotify();
  }

  /// 在 build / layout / paint 阶段被写入时，延迟通知到下一帧再 fire，
  /// 避免 InheritedProviderScope 在祖先 build 已完成后被 markNeedsBuild
  /// 触发 "setState/markNeedsBuild called during build" 断言。
  ///
  /// 触发场景：子页 `initState` / `_resetState` 里写 `editingItem = false`
  /// 把上一份子页遗留的全局编辑态归零（T3 之后子页改读 Provider，写路径上
  /// 链路是 `setter → notifyListeners → InheritedProvider.markNeedsBuild`）。
  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
