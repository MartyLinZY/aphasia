import 'dart:convert';

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

import '../../models/typedef.dart';
import '../io/file.dart';


Future<String> generatedAudioUrl (String text) async {
  var jsonData = await HttpClientManager().post(url: "${HttpConstants.backendBaseUrl}/api/proxy/audio_from_text", body: jsonEncode({
    "text": text
  }));

  return jsonData['url'];
}

Future<String> uploadFile(WrappedFile file, FileType fileType) async {
  MediaType mediaType;
  String requestPath;
  if (fileType == FileType.image) {
    // 后端不区分具体的图片文件，所以这里可以统一为png
    mediaType = MediaType("image", "png");
    requestPath = "/api/image";
  } else if (fileType == FileType.audio) {
    // 后端不区分具体的音频文件，所以这里可以统一为mpeg
    mediaType = MediaType("audio", "mpeg");
    requestPath = "/api/audio";
  } else {
    throw UnimplementedError("不应该出现的fileType ${fileType.name}");
  }

  MultipartFile multipartFile = MultipartFile.fromBytes("file", file.bytes!, filename: file.name, contentType: mediaType);
  var jsonData = await HttpClientManager().multipartRequest(file: multipartFile, authority: HttpConstants.backendBaseUrlWithoutProtocol, path: requestPath);

  return jsonData['url'];
}

Future<List<JsonObject>> getUploadedAudios() async {
  var jsonData = await HttpClientManager().get(
      url: "${HttpConstants.backendBaseUrl}/api/audios");

  List<JsonObject> audios = [];
  for (var obj in jsonData) {
    audios.add({
      "name": obj['name'],
      "url": obj['url']
    });
  }


  return audios;
}

Future<List<JsonObject>> getUploadedImages() async {
  var jsonData = await HttpClientManager().get(url: "${HttpConstants.backendBaseUrl}/api/images");

  List<JsonObject> images = [];
  for (var obj in jsonData) {
    images.add({
      "name": obj['name'],
      "url": obj['url']
    });
  }


  return images;
  // return [
  //   {
  //     "name": "firstImage",
  //     "url": "https://img1.baidu.com/it/u=1671025097,439798995&fm=253&fmt=auto&app=138&f=JPEG?w=755&h=500",
  //   },
  //   {
  //     "name": "secondImage",
  //     "url": "https://photo.16pic.com/00/75/74/16pic_7574368_b.jpg",
  //   },
  //   {
  //     "name": "thirdImage",
  //     "url": "https://photo.16pic.com/00/66/19/16pic_6619056_b.jpg",
  //   },
  // ];
}