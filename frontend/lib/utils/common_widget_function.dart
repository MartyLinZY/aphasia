import 'dart:io' show Platform;

import 'package:aphasia_recovery/enum/system.dart';
import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/exceptions/local_exceptions.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'io/file.dart';

void toast(BuildContext context, {required String msg, required String btnText, void Function ()? onPressed, CommonStyles? commonStyles}) {
  onPressed ??= (){};

  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: commonStyles?.bodyStyle?.copyWith(color: commonStyles.onPrimaryColor),),
        action: SnackBarAction(label: btnText, onPressed: onPressed),
      )
  );
}

/// 弹一个确认对话框，返回 [Future<bool?>]——确认 / 取消 / 外部关闭分别
/// 解析为 true / false / null。
///
/// **caller 自己负责在 [onConfirm] / [onCancel] 里 `Navigator.pop`**——
/// 仓库内现有 29 处 caller 全部按此写法。早期实现里 helper 内部还会再
/// 跑一次 `Navigator.pop(context, true/false)`，与 caller 的 pop 叠加成
/// 双 pop——会顺手把 dialog 下面的父路由也弹掉。真实 app 因为外层通常
/// 还压着别的 route 才被掩盖，widget test 里 home 是单 route 时直接
/// 屏空白；某些 caller（如 doctor_item_slot_edit_dialog.dart:120 双
/// pop 主动返 ItemSlot）甚至会把更上一层路由也带走。
///
/// 现行规约：
/// - caller 没传 [onConfirm]：默认 `Navigator.pop(ctx, true)` 关 dialog；
/// - caller 没传 [onCancel]：默认 `Navigator.pop(ctx, false)` 关 dialog；
/// - caller 传了回调：helper 不再额外 pop，回调里**必须**自己 pop（不然
///   dialog 关不掉）。
Future<bool?> confirm (BuildContext context, {
  required String title,
  required String body,
  void Function(BuildContext dialogContext)? onConfirm,
  void Function(BuildContext dialogContext)? onCancel,
  required CommonStyles? commonStyles}) {

  return showDialog<bool?>(context: context, builder: (context) {
    return buildSimpleActionDialog(context,
      title: title,
      body: Text(body, style: commonStyles?.bodyStyle,),
      commonStyles: commonStyles,
      onConfirm: onConfirm ?? (ctx) => Navigator.pop(ctx, true),
      onCancel: onCancel ?? (ctx) => Navigator.pop(ctx, false),
    );
  });
}

// void confirm (BuildContext context, {
//   required String title,
//   required String body,
//   void Function(BuildContext dialogContext)? onConfirm,
//   void Function(BuildContext dialogContext)? onCancel,
//   required CommonStyles? commonStyles}) {

//   showDialog(context: context, builder: (context) {
//     return buildSimpleActionDialog(context,
//       title: title,
//       body: Text(body, style: commonStyles?.bodyStyle,),
//       commonStyles: commonStyles,
//       onConfirm: onConfirm,
//       onCancel: onCancel
//     );
//   });
// }

Dialog buildSimpleActionDialog(BuildContext context, {
  required String title,
  required Widget body,
  void Function (BuildContext dialogContext)? onCancel,
  void Function (BuildContext dialogContext)? onConfirm,
  required CommonStyles? commonStyles,
  ScrollController? controller,
}) {
  onCancel ??= (context) => Navigator.pop(context);
  onConfirm ??= (context) => Navigator.pop(context);

  final mediaSize = MediaQuery.of(context).size;
  final commonPaddingWidth = commonStyles?.commonPaddingWidth ?? 18.0;

  return Dialog(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: mediaSize.width * 0.75,
          child: Padding(
            padding: EdgeInsets.only(left: commonPaddingWidth, right: commonPaddingWidth, top: commonPaddingWidth, bottom: commonPaddingWidth / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(title, style: commonStyles?.titleStyle,)
                ),
                Divider(color: Colors.white38, thickness: 2.0, height: commonPaddingWidth),
                Container(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.5),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: EdgeInsets.all(commonPaddingWidth),
                      child: body,
                    ),
                  ),
                ),
                Divider(color: Colors.white38, thickness: 2.0, height: commonPaddingWidth),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () => onCancel!(context),
                        child: Text("取消", style: commonStyles?.bodyStyle,)
                    ),
                    const SizedBox(width: 16,),
                    ElevatedButton(
                      onPressed: () => onConfirm!(context),
                      style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
                      child: Text("确认", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles.onPrimaryColor),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    ),
  );
}

Map<String, dynamic> createActionButtonSetting({required String btnTooltipMsg, required Icon btnIcon, required Function ()? btnAction,}) {
  return {
    "tooltip": btnTooltipMsg,
    "icon": btnIcon,
    "action": btnAction,
  };
}

Widget buildListTileContentWithActionButtons({
  required Widget body,
  required double textAreaMaxHeight,
  required double textAreaMaxWidth,
  required CommonStyles? commonStyles,
  double buttonSize = 30.0,
  String? firstBtnTooltipMsg,
  Icon? firstBtnIcon,
  Function ()? firstBtnAction,
  String? secondBtnTooltipMsg,
  Icon? secondBtnIcon,
  Function ()? secondBtnAction,
  List<Map<String, dynamic>>? moreButtons,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  List<Widget> buttons = [];
  if (firstBtnIcon != null) {
    assert(firstBtnTooltipMsg != null);
    buttons.add(SizedBox(
        width: buttonSize,
        child: Tooltip(
            message: firstBtnTooltipMsg,
            child: TextButton(
              onPressed: firstBtnAction,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0.0)),
              child: firstBtnIcon,
            )
        )
    ));
  }

  if (secondBtnIcon != null) {
    assert(secondBtnTooltipMsg != null);
    buttons.add(SizedBox(
        width: buttonSize,
        child: Tooltip(
            message: secondBtnTooltipMsg,
            child: TextButton(
              onPressed: secondBtnAction,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0.0)),
              child: secondBtnIcon,
            )
        )
    ));
  }

  if (moreButtons != null) {
    for (var btnSetting in moreButtons) {
      buttons.add(SizedBox(
          width: buttonSize,
          child: Tooltip(
              message: btnSetting['tooltip'],
              child: TextButton(
                onPressed: btnSetting['action'],
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0.0)),
                child: btnSetting['icon'],
              )
          )
      ));
    }
  }

  return Row (
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    mainAxisSize: mainAxisSize,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: textAreaMaxHeight,
          maxWidth: textAreaMaxWidth,
        ),
        child: OverflowBox(
            alignment: AlignmentDirectional
                .centerStart,
            child: body
        ),
      ),
      Row(
        children: buttons,
      ),
    ],
  );
}


Widget buildInputFormField (
    String label,
    GlobalKey<FormFieldState> fieldKey,
    TextEditingController controller,
    String? Function(String? value) validator,
    {
      double? width,
      int? maxLines = 1,
      int? minLines,
      int? maxLength,
      int errorMaxLines = 2,
      bool obscureText = false,
      bool enableSuggestions = true,
      bool autocorrect = true,
      required CommonStyles? commonStyles,
    }) {
  return Row(
    children: [
      Text(label, style: commonStyles?.bodyStyle,),
      SizedBox(
        width: width ?? 150,
        child: TextFormField(
          key: fieldKey,
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(border: const OutlineInputBorder(), errorMaxLines: errorMaxLines),
          style: commonStyles?.bodyStyle,
          maxLines: maxLines,
          maxLength: maxLength,
        ),
      )
    ],
  );
}

Widget buildImagePreview({String? imageUrl, String? imageAssetPath, CommonStyles? commonStyles, bool showTitle = true}) {
  List<Widget> titlePart = [];
  if (showTitle) {
    titlePart = [
      Text("图片预览：", style: commonStyles?.bodyStyle,),
      const SizedBox(height: 16,),
    ];
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      ...titlePart,
      Builder(
          builder: (context) {
            var media = MediaQuery.of(context);
            double imageBoxWidth = media.size.width / 3;
            Widget imagePreview;
            if (imageUrl != null || imageAssetPath != null) {
              imagePreview = buildUrlOrAssetsImage(context,
                imageUrl: imageUrl ?? imageAssetPath!,
                width: imageBoxWidth,
                height: imageBoxWidth,
                commonStyles: commonStyles
              );
            } else {
              imagePreview = Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: SizedBox(
                  width: imageBoxWidth,
                  height: imageBoxWidth,
                  child: Center(
                    child: Text("暂无图片",
                      style: commonStyles?.bodyStyle,
                    ),
                  ),
                ),
              );
            }

            return imagePreview;
          }
      ),

    ],
  );
}

Widget buildUrlOrAssetsImage(BuildContext context, {
  required String imageUrl,
  required CommonStyles? commonStyles,
  double? height,
  double? width,
}) {
  Widget imageWidget;
  if (!imageUrl.startsWith("assets/")) {
    imageWidget = Image.network(imageUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  } else {
    imageWidget = Image.asset(imageUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  return imageWidget;
}

Widget buildInnerShadowedBox({required Widget child, Color? backgroundColor, Color? shadowColor}) {
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? Colors.grey,
        ),
        BoxShadow(
            color: backgroundColor ?? Colors.white,
            spreadRadius: -2.0,
            blurRadius: 2.0
        )
      ],
    ),
    child: child,
  );
}

Widget wrappedByCard({required Widget child, double? elevation}) {
  return Card(
    elevation: elevation,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: child,
    ),
  );
}

void requestResultErrorHandler(BuildContext context, {dynamic error}) {
  if (!context.mounted) {
    return;
  }

  debugPrint("错误类型: ${error.runtimeType}");
  switch (error.runtimeType) {
    case EditPublishedQuestionSetException:
      toast(context, msg: "测评已发布，无法修改", btnText: "确认");
      break;
    case ExamNotFoundException:
      toast(context, msg: error.toString(), btnText: "确认");
      break;
    case InCompleteExamException:
      toast(context, msg: (error as InCompleteExamException).message, btnText: "确认");
    default:
      toast(context, msg: '出现错误，请重试或联系开发者', btnText: '确认', onPressed: () { });
      throw error;
  }
}

PlatformType getPlatformType() {
  if (const bool.fromEnvironment('dart.library.js_util')) {
    return PlatformType.web;
  }
  if (Platform.isAndroid) {
    return PlatformType.android;
  }
  if (Platform.isFuchsia) {
    return PlatformType.fuchsia;
  }
  if (Platform.isIOS) {
    return PlatformType.iOS;
  }
  if (Platform.isLinux) {
    return PlatformType.linux;
  }
  if (Platform.isMacOS) {
    return PlatformType.macOS;
  }
  if (Platform.isWindows) {
    return PlatformType.windows;
  }
  throw UnimplementedError("无法识别当前平台");
}

bool isChineseString(String value) {
  RegExp regExp = RegExp(r'^[\u4e00-\u9fa5]+$');
  return regExp.hasMatch(value);
}