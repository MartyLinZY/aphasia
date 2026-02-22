import 'dart:convert';
import 'dart:typed_data';

import 'package:aphasia_recovery/models/typedef.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:http/http.dart';

/// 调用后端翻译服务，对文本进行补全/猜测并返回翻译结果。
Future<String> translateText(String text) async {
  if (text.trim().isEmpty) return text;
  JsonObject result = await HttpClientManager().post(
    url: "${HttpConstants.backendBaseUrl}/api/translate",
    body: jsonEncode({"text": text}),
  );
  return result['translatedText'] ?? text;
}

Future<String> recognizeAudioContent(List<int> rawPcm16Data) async {
  final pcm16File =
      MultipartFile.fromBytes("file", rawPcm16Data, filename: "recorded.pcm");

  JsonObject result = await HttpClientManager().multipartRequest(
      authority: HttpConstants.backendBaseUrlWithoutProtocol,
      path: "/api/proxy/audio_recognize",
      file: pcm16File);

  return result['content'];
}

Future<JsonObject> audioFluency(List<int> rawPcm16Data) async {
  final pcm16File =
      MultipartFile.fromBytes("file", rawPcm16Data, filename: "recorded.pcm");

  JsonObject result = await HttpClientManager().multipartRequest(
      authority: HttpConstants.backendBaseUrlWithoutProtocol,
      path: "/api/proxy/fluency",
      file: pcm16File);

  return result;
}

Future<double> textSimilarity(String text1, String text2) async {
  JsonObject result = await HttpClientManager().post(
      url:
          "${HttpConstants.backendBaseUrl}/api/proxy/text_similarity?text1=$text1&text2=$text2",
      body: "");

  return result['sim'];
}

Future<String> handWritingRecognize(Uint8List imageData) async {
  final imageFile =
      MultipartFile.fromBytes("file", imageData, filename: "handWrite.png");
  JsonObject result = await HttpClientManager().multipartRequest(
      file: imageFile,
      authority: HttpConstants.backendBaseUrlWithoutProtocol,
      path: "/api/proxy/handwrite_recognize");

  return result['content'];
}

void main() async {
  // final sim = await textSimilarity("我是安安", "安安是我");
  // print(sim);
}
