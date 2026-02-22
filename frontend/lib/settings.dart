class HttpConstants {
  HttpConstants._();
  // static const String backendBaseUrl = "http://localhost:8080";
  // static const String backendBaseUrlWithoutProtocol = "localhost:8080";
  static const String backendBaseUrl = "http://192.168.0.110:8080";
  static const String backendBaseUrlWithoutProtocol = "192.168.0.110:8080";
}

class AppSettings {
  AppSettings._();
  static bool testMode = false;
  static const String notInTestModeErrMsg = "该属性仅在测试函数中时可直接赋值，如果是test()函数，请在测试代码开头写上TestBase.commonSetup()";


  // 百度云开放平台api相关 - 未使用 - 所有请求全部由后端代理发送
  static const authorizeUrl = "https://aip.baidubce.com/oauth/2.0/token";
  static const appId = "";
  static const clientSecrete = "";
  static const apiKey = "";
}