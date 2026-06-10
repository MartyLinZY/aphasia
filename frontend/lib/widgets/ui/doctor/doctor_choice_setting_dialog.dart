import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/file.dart';
import '../../../utils/http/http_common.dart';
import '../common/common.dart';

class ChoiceSettingDialog extends StatefulWidget {
  final Choice? choice;
  const ChoiceSettingDialog({super.key, this.choice});

  @override
  State<ChoiceSettingDialog> createState() => _ChoiceSettingDialogState();
}

class _ChoiceSettingDialogState extends State<ChoiceSettingDialog>
    with UseCommonStyles {
  Choice? currChoice;

  // 新增样式常量
  static const _dialogRadius = 20.0;
  static const _buttonSpacing = 16.0;
  static const _iconSize = 20.0;

  final _formKey = GlobalKey<FormState>(debugLabel: "choiceFormKey");
  final _choiceNameKey = GlobalKey<FormFieldState>(debugLabel: "choiceNameKey");
  final choiceNameCtrl = TextEditingController();

  String? imageUrl;
  String? imageAssetPath;

  String? choiceNameValidator(String? value) {
    if (value == null || value == "") {
      return "选项名称不可为空";
    }
    return null;
  }

  void resetState() {
    if (widget.choice != null) {
      currChoice = widget.choice;
      imageUrl = widget.choice!.imageUrl;
      imageAssetPath = widget.choice!.imageAssetPath;
      choiceNameCtrl.text = widget.choice!.text;
    }
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  // 新增处理方法
  void _handleUpload() {
    void doPickFile() {
      pickImageFile().then((imgFile) {
        if (imgFile != null) {
          uploadFile(imgFile, FileType.image).then((url) {
            setState(() => imageUrl = url);
          }).catchError(
              (err) => requestResultErrorHandler(context, error: err));
        }
      });
    }

    _confirmBeforeAction(
        message: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", action: doPickFile);
  }

  void _handleSelectExisting() {
    void doSelect() {
      showDialog<String>(
              context: context,
              builder: (context) => const SelectExistingImageDialog())
          .then((url) => setState(() => imageUrl = url));
    }

    _confirmBeforeAction(
        message: "选项已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", action: doSelect);
  }

  void _handleSelectBuiltIn() {
    void doSelect() {
      showDialog<String>(
              context: context,
              builder: (context) =>
                  const SelectExistingImageDialog(isBuiltIn: true))
          .then((path) => setState(() {
                imageAssetPath = path;
                imageUrl = null;
              }));
    }

    _confirmBeforeAction(
        message: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", action: doSelect);
  }

  // 通用确认方法
  void _confirmBeforeAction(
      {required String message, required VoidCallback action}) {
    if (imageUrl != null || imageAssetPath != null) {
      confirm(context, title: "确认", body: message, commonStyles: commonStyles,
          onConfirm: (context) {
        Navigator.pop(context);
        action();
      });
    } else {
      action();
    }
  }

  Widget _buildImageButton(
      String text, IconData icon, VoidCallback action, Color color) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: _iconSize),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        backgroundColor: color,
      ),
      onPressed: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currChoice != widget.choice) {
      resetState();
    }

    initStyles(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: buildSimpleActionDialog(context,
          title: "选项设置",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInputFormField(
                  "选项名称：", _choiceNameKey, choiceNameCtrl, choiceNameValidator,
                  commonStyles: commonStyles, maxLength: 20),
              const SizedBox(height: _buttonSpacing),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Text("选项图片：", style: commonStyles?.bodyStyle,),
              //     ElevatedButton(
              //         onPressed: () {
              //           doPickFile () {
              //             pickImageFile().then((imgFile) {
              //               if (imgFile != null) {
              //                 uploadFile(imgFile, FileType.image).then((url) {
              //                   setState(() {
              //                     imageUrl = url;
              //                   });
              //                 }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
              //               }
              //             });
              //           }
              //           if (imageUrl != null || imageAssetPath != null) {
              //             confirm(context, title: "确认", body: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", commonStyles: commonStyles,
              //                 onConfirm: (context) {
              //                   Navigator.pop(context);
              //                   doPickFile();
              //                 }
              //             );
              //           } else {
              //             doPickFile();
              //           }
              //         },
              //         child: Text("上传图片", style: commonStyles?.bodyStyle,)
              //     ),
              //     const SizedBox(width: 16,),
              //     ElevatedButton(
              //         onPressed: () {
              //           doSelectImage() {
              //             showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog()).then((url) {
              //               setState(() {
              //                 imageUrl = url;
              //               });
              //             });
              //           }
              //           if (imageUrl != null || imageAssetPath != null) {
              //             confirm(context, title: "确认", body: "选项已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
              //                 onConfirm: (context) {
              //                   Navigator.pop(context);
              //                   doSelectImage();
              //                 }
              //             );
              //           } else {
              //             doSelectImage();
              //           }
              //         },
              //         child: Text("已上传的图片", style: commonStyles?.bodyStyle,)
              //     ),
              //     const SizedBox(width: 16,),
              //     ElevatedButton(
              //         onPressed: () {
              //           doSelectImage() {
              //             showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog(isBuiltIn: true,)).then((path) {
              //               setState(() {
              //                 imageAssetPath = path;
              //                 imageUrl = null;
              //               });
              //             });
              //           }
              //           if (imageUrl != null || imageAssetPath != null) {
              //             confirm(context, title: "确认", body: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
              //                 onConfirm: (context) {
              //                   Navigator.pop(context);
              //                   doSelectImage();
              //                 }
              //             );
              //           } else {
              //             doSelectImage();
              //           }
              //         },
              //         child: Text("系统内置图片", style: commonStyles?.bodyStyle,)
              //     ),
              //   ],
              // ),
              Wrap(
                spacing: _buttonSpacing,
                runSpacing: _buttonSpacing,
                children: [
                  _buildImageButton(
                      "上传图片", Icons.upload, _handleUpload, Colors.blueAccent),
                  _buildImageButton(
                      "已上传", Icons.image, _handleSelectExisting, Colors.green),
                  _buildImageButton("系统内置", Icons.photo_library,
                      _handleSelectBuiltIn, Colors.orange),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              buildImagePreview(
                  imageUrl: imageUrl,
                  imageAssetPath: imageAssetPath,
                  commonStyles: commonStyles),
              const SizedBox(
                height: 16,
              ),
              imageUrl == null && imageAssetPath == null
                  ? const SizedBox.shrink()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          imageUrl = null;
                          imageAssetPath = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: commonStyles?.errorColor),
                      child: Text(
                        "移除图片",
                        style: commonStyles?.bodyStyle
                            ?.copyWith(color: commonStyles?.onErrorColor),
                      ),
                    ),
            ],
          ),
          commonStyles: commonStyles, onConfirm: (context) {
        if (_formKey.currentState!.validate()) {
          Navigator.pop(
              context,
              Choice(
                  imageUrl: imageUrl,
                  imageAssetPath: imageAssetPath,
                  text: choiceNameCtrl.text));
        }
      }),
    );
  }
}
