class HttpConstants {
  HttpConstants._();
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String backendBaseUrlWithoutProtocol = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: 'localhost:8080',
  );

  /// 把相对媒体路径（如 `/prompts/x.mp3`）拼成完整 URL（用当前 BACKEND_URL）；
  /// 已是 http(s):// 的绝对地址原样返回。种子里的题干/提示音存相对路径即可跨端正确：
  /// web/Docker=localhost、Android 模拟器=10.0.2.2、真机=局域网 IP，不再写死 localhost。
  static String resolveMedia(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String base = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }
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