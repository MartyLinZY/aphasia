import 'package:shared_preferences/shared_preferences.dart';

class WrappedSharedPref {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  WrappedSharedPref._();

  static WrappedSharedPref? instance;

  factory WrappedSharedPref() {
    if (instance == null) {
      instance = WrappedSharedPref._();
      return instance!;
    } else {
      return instance!;
    }
  }

  Future<bool> saveToken(String token) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.setString("Token", token);
  }

  Future<String?> retrieveToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("Token");
  }

  Future<bool> deleteToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.remove("Token");
  }
}