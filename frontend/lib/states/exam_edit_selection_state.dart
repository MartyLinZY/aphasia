import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 套题编辑页面的"当前选中/编辑项"状态。
///
/// 承载原本散落在 [DoctorExamEditPageState] 上的 4 个 selection 字段
/// （`editItem` / `editCategoryIndex` / `editSubCategoryIndex` / `editingItem`），
/// 以及暂存的 `editQuestionIndex`。
///
/// T2 阶段：State 通过 getter/setter 代理到这里，行为不变；后续 T3 起子页与
/// 左栏树拆出的 Widget 会直接 `context.read/watch` 此 Notifier，实现真正解耦。
/// T8 会在此类上加入 `onCategoryDeleted` / `onSubCategoryDeleted` 等业务方法
/// 并补单测。
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
