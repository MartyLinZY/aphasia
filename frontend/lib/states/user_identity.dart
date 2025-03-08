import 'dart:async';
import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:flutter/foundation.dart';

import '../settings.dart';



class UserIdentity extends ChangeNotifier {
  final String _identity;
  final String _uid;
  final String _token;
  /// 1表示患者，2表示医生
  final int _role;

  String get identity => _identity;

  String get uid => _uid;

  String get token => _token;

  bool get isPatient => _role == 1;
  bool get isDoctor => _role == 2;

  UserIdentity({required String identity, required String uid, required String token, required int role})
      : _identity = identity,
        _uid = uid,
        _token = token,
        _role = role;

  static Future<UserIdentity?> authWithToken() async {
    String? savedToken = await WrappedSharedPref().retrieveToken();
    if(savedToken == null) {
      return null;
    }

    try {
      Map<String, dynamic> jsonData = await HttpClientManager().post(url: '${HttpConstants.backendBaseUrl}/api/auth', body: '', headers: {"Token": savedToken});
      // Map<String, dynamic> jsonData = {"uid": "1", "token": "?oldToken\$", "role": 2, "identity": "phoneOrNumber"};
      UserIdentity identity = UserIdentity(identity: jsonData['identity'], uid: jsonData['uid'], token: jsonData['token'], role: jsonData['role']);

      await WrappedSharedPref().saveToken(identity.token);

      return identity;
    } on HttpRequestException catch (e) {
      if (e.statusCode == 403) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  static Future<UserIdentity?> login({required String identity, required String password}) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager()
          .post(url: '${HttpConstants.backendBaseUrl}/api/auth' , body: '', headers: {"identity": identity, "password": password}, setToken: false);
      // Map<String, dynamic> jsonData = {"uid": "1", "token": "?oldToken\$", "role": 2, "identity": "phoneOrNumber"};
      UserIdentity userIdentity = UserIdentity(identity: jsonData['identity'], uid: jsonData['uid'], token: jsonData['token'], role: jsonData['role']);

      await WrappedSharedPref().saveToken(userIdentity.token);

      return userIdentity;
    } on HttpRequestException catch (e) {
      if (e.statusCode == 403) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  static Future<void> logout() async{
    await WrappedSharedPref().deleteToken();
  }

  static Future<UserIdentity?> register(Map<String, String> registerInfo) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager()
          .post(url: '${HttpConstants.backendBaseUrl}/api/register' , body: jsonEncode(registerInfo));
      UserIdentity identity = UserIdentity(identity: jsonData['identity'], uid: jsonData['uid'], token: jsonData['token'], role: jsonData['role']);

      await WrappedSharedPref().saveToken(identity.token);

      return identity;
    } on HttpRequestException catch (e) {
      if (e.statusCode == 403) {
        return null;
      } else {
        rethrow;
      }
    }
  }

}