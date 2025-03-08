import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

const String assetsDir = "assets";
const String assetsImageDir = "images";

Future<List<String>> getAssets([BuildContext? context]) async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(context == null ? rootBundle : DefaultAssetBundle.of(context));
  return assetManifest.listAssets();
}

Future<List<String>> getImageAssets ([BuildContext? context]) async {
  final assets = await getAssets(context);
  return assets.where((e) => e.startsWith("$assetsDir/$assetsImageDir/")).toList();
}

Future<List<Map<String, String>>> getImageForQuestionSetting ([BuildContext? context]) async {
  final images = await getImageAssets(context);
  return images.where((e) => e.startsWith("$assetsDir/$assetsImageDir/for_question_setting/"))
      .map((e) => {
        'name': e.split("/").last,
        'url': e
  }).toList();
}

bool isImageUrlAssets (String? imageUrl) {
  if (imageUrl != null) {
    return imageUrl.startsWith("$assetsDir/$assetsImageDir/");
  }
  return false;
}
