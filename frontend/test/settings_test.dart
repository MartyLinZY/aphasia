import 'package:aphasia_recovery/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 测试环境没注入 --dart-define=BACKEND_URL，走默认 http://localhost:8080。
  group('HttpConstants.resolveMedia', () {
    test('相对路径（带前导斜杠）拼成 BACKEND_URL', () {
      expect(HttpConstants.resolveMedia('/prompts/q1.mp3'),
          'http://localhost:8080/prompts/q1.mp3');
    });

    test('相对路径（无前导斜杠）补斜杠后拼接', () {
      expect(HttpConstants.resolveMedia('prompts/q1.mp3'),
          'http://localhost:8080/prompts/q1.mp3');
    });

    test('已是绝对 http(s) 地址原样返回（如医生上传的音频）', () {
      expect(HttpConstants.resolveMedia('http://example.com/a.mp3'),
          'http://example.com/a.mp3');
      expect(HttpConstants.resolveMedia('https://cdn.x/y.mp3'),
          'https://cdn.x/y.mp3');
    });
  });
}
