import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/file.dart';
import '../../../utils/http/http_common.dart';
import '../common/common.dart';

class ItemSlotEditDialog extends StatefulWidget {
  final ItemSlot slot;
  final int slotIndex;
  final EvalCommandQuestionByCorrectActionCount rule;
  const ItemSlotEditDialog(
      {super.key,
      required this.slot,
      required this.rule,
      required this.slotIndex});

  @override
  State<ItemSlotEditDialog> createState() => _ItemSlotEditDialogState();
}

class _ItemSlotEditDialogState extends State<ItemSlotEditDialog>
    with UseCommonStyles {
  // 新增样式常量
  static const _buttonSpacing = 16.0;
  static const _iconSize = 20.0;
  static const _dialogRadius = 20.0;

  // 用于判断dialog外部状态是否改变过
  ItemSlot? currSlot;
  final _itemNameFieldKey =
      GlobalKey<FormFieldState>(debugLabel: "itemNameFieldKey");
  final itemNameCtrl = TextEditingController();
  String? imageUrl;
  String? imageAssetPath;

  void resetState() {
    currSlot = widget.slot;
    imageUrl = currSlot?.itemImageUrl;
    imageAssetPath = currSlot?.itemImageAssetPath;
    itemNameCtrl.text = currSlot?.itemName ?? "";
  }

  String? itemNameValidator(String? value) {
    if (value == null || value == "") {
      return "物体名称不可为空";
    } else {
      int index = widget.rule.indexOfItemName(value);
      if (index != -1) {
        return "物体名称不能重复，当前名称与第${index + 1}个区域内物体重复";
      }
    }
    return null;
  }

  @override
  void initState() {
    resetState();
    super.initState();
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

    _confirmBeforeAction(message: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", action: doPickFile).then((confirmed) {
      if (confirmed ?? false) {
        doPickFile();
      }
    });
  }

  void _handleSelectExisting() {
    void doSelect() {
      showDialog<String>(
              context: context,
              builder: (context) => const SelectExistingImageDialog())
          .then((url) => setState(() => imageUrl = url));
    }

    _confirmBeforeAction(message: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", action: doSelect).then((confirmed) {
      if (confirmed ?? false) {
        doSelect();
      }
    });
  }

  void _handleSelectBuiltIn() {
    void doSelect() {
      showDialog<String>(
              context: context,
              builder: (context) =>
                  const SelectExistingImageDialog(isBuiltIn: true))
          .then((path) => setState(() => imageAssetPath = path));
    }

    _confirmBeforeAction(message: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", action: doSelect).then((confirmed) {
      if (confirmed ?? false) {
        doSelect();
      }
    });
  }

  void _showClearConfirmation() {
    confirm(context, title: "确认", body: "确认要清空该区域吗", commonStyles: commonStyles,
        onConfirm: (context) {
      Navigator.pop(context);
      Navigator.pop(context, ItemSlot());
    });
  }

  // 通用确认方法
   Future<bool?> _confirmBeforeAction(
      {required String message, required VoidCallback action}) {
    if (imageUrl != null || imageAssetPath != null) {
      return confirm(context,
          title: "确认",
          body: message,
          commonStyles: commonStyles,
          onConfirm: (context) {
            Navigator.pop(context, true);  // 明确返回bool类型
            action();
          },
          onCancel: (context) => Navigator.pop(context, false)  // 添加取消处理
      );
    } else {
      action();
      return Future.value(true);  // 立即返回成功结果
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
    if (currSlot != widget.slot) {
      resetState();
    }

    initStyles(context);

    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: buildSimpleActionDialog(context,
          title: "操作区域设置",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ElevatedButton(
              //   onPressed: () {
              //     confirm(context, title: "确认", body: "确认要清空该区域吗", commonStyles: commonStyles,
              //         onConfirm: (context) {
              //           // 关闭confirm dialog
              //           Navigator.pop(context);
              //           // 关闭操作区域设置dialog
              //           Navigator.pop(context, ItemSlot());
              //         }
              //     );
              //   },
              //   style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
              //   child: Text("清空区域", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor),),
              // ),
              // 优化后的清空按钮
              ElevatedButton.icon(
                icon: const Icon(Icons.clear, size: _iconSize),
                label: const Text("清空区域"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: commonStyles?.errorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_dialogRadius),
                  ),
                ),
                onPressed: () => _showClearConfirmation(),
              ),
              const Divider(),
              buildInputFormField(
                  "物体名称：", _itemNameFieldKey, itemNameCtrl, itemNameValidator,
                  commonStyles: commonStyles,
                  maxLength: 20,
                  errorMaxLines: 2,
                  width: 200),
              const SizedBox(height: _buttonSpacing),
              // Wrap(
              //   runSpacing: 16.0,
              //   children: [
              //     Text("物体示意图：", style: commonStyles?.bodyStyle,),
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
              //                 imageAssetPath = null;
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
        if (_itemNameFieldKey.currentState!.validate() &&
            (imageUrl != null || imageAssetPath != null)) {
          Navigator.pop(
              context,
              ItemSlot(
                  itemImageUrl: imageUrl,
                  itemImageAssetPath: imageAssetPath,
                  itemName: itemNameCtrl.text));
        }

        if (imageUrl == null && imageAssetPath == null) {
          toast(context,
              msg: "请上传一张图片或从已上传的图片或者系统内置图案中选择一张图片作为物体的图片", btnText: "确认");
        }
      }),
    );
  }
}
