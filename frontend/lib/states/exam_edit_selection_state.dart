import 'package:flutter/foundation.dart';

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
    _editItem = v;
    notifyListeners();
  }

  set editCategoryIndex(int? v) {
    _editCategoryIndex = v;
    notifyListeners();
  }

  set editSubCategoryIndex(int? v) {
    _editSubCategoryIndex = v;
    notifyListeners();
  }

  set editQuestionIndex(int? v) {
    _editQuestionIndex = v;
    notifyListeners();
  }

  set editingItem(bool v) {
    _editingItem = v;
    notifyListeners();
  }
}
