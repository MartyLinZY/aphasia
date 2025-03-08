import 'package:flutter/material.dart';

@Deprecated("已废弃，功能并入user_identity")
class UserInfo extends ChangeNotifier {
  int? _role;
  String? _name;
  String? _phoneOrEmail;

  /// 1表示患者，2表示医生
  int? get role => _role;

  String? get name => _name;

  UserInfo ({int?role, String? name, String? phoneOrEmail})
    : _phoneOrEmail = phoneOrEmail,
      _role = role,
      _name = name;

  set role(int? newRole) {
    _role = newRole;
    notifyListeners();
  }

  set name(String? newName) {
    _name = newName;
    notifyListeners();
  }

  set phoneOrEmail(String? phoneOrEmail) {
    _phoneOrEmail = phoneOrEmail;
    notifyListeners();
  }
}