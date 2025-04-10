import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/typedef.dart';
import '../../../utils/io/assets.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/file.dart';
import '../../../utils/http/http_common.dart';

class CircleIconSwitchTextButton extends StatelessWidget {
  // 新增样式常量
  static const _buttonSize = 48.0;
  static const _elevation = 6.0;
  static const _iconSize = 24.0;

  final int state;
  final List<Map<String, dynamic>> btnSetting;

  static Map<String, dynamic> btnSettingWith({required Icon btnIcon, required void Function() btnAction, required String btnTooltipMsg}) {
    return {
      "btnIcon": btnIcon,
      "btnAction": btnAction,
      "btnTooltipMsg": btnTooltipMsg
    };
  }

  /// [btnSetting] 中每个map包含且仅包含[Icon btnIcon], [void Function() btnAction], [String btnTooltipMsg]，例如
  /// [{"btnIcon": Icon(Icons.edit), "btnAction": (){}, "btnTooltipMsg": "编辑"}]
  /// [state] 按钮当前处于第几个状态
  const CircleIconSwitchTextButton({super.key, required this.btnSetting, required this.state})
    : assert(state < btnSetting.length && state >= 0);

  @override
  Widget build(BuildContext context) {
    var setting = btnSetting[state];

    return SizedBox(
      // width: 40, // 增加宽度
      // height: 40, // 增加高度
      // child: ElevatedButton (
      //   style: ElevatedButton.styleFrom(
      //   padding: EdgeInsets.zero, // 去除内边距
      //   shape: const CircleBorder(), // 圆形按钮
      //   backgroundColor: Colors.blueAccent, // 背景颜色
      //   elevation: 5, // 阴影效果
      // ),
      width: _buttonSize,
      height: _buttonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        backgroundColor: setting['btnIcon'].color ?? Colors.blueAccent,
        elevation: _elevation,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
       onPressed: setting['btnAction'],
      child: Tooltip(
        message: setting['btnTooltipMsg'],
        child: IconTheme(
          data: const IconThemeData(color: Colors.white), // 图标颜色
          child: setting['btnIcon'],
        ),
      ),
      ),
    );
  }
}

class TextOrTextField extends StatelessWidget with UseCommonStyles {
  // 新增样式常量
  static const _maxInputWidth = 280.0;
  static const _borderRadius = 12.0;
  static const _focusBorderWidth = 2.0;
  static const _iconSize = 24.0;

  final bool editing;
  final TextEditingController controller;
  final void Function() onQuitEditing;
  final void Function() onEnterEditing;
  final String Function(String? value) validator;
  final void Function(String newVal) onChanged;

  TextOrTextField({
    super.key,
    required this.editing,
    required this.controller,
    required this.onQuitEditing,
    required this.onEnterEditing,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    // Widget textOrInput;
    // Widget actionBtn;

    // if (editing) {
    //   textOrInput = Container(
    //     constraints: const BoxConstraints(maxWidth: 200, minWidth: 100),
    //     child: TextFormField(
    //       autofocus: true,
    //       controller: controller,
    //       maxLength: 50,
    //       onChanged: onChanged,
    //       onEditingComplete: onQuitEditing,
    //       validator: validator,
    //       decoration: InputDecoration(
    //         enabledBorder: OutlineInputBorder(
    //           borderSide: const BorderSide(color: Colors.grey),
    //           borderRadius: BorderRadius.circular(10),
    //         ),
    //         focusedBorder: OutlineInputBorder(
    //           borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
    //           borderRadius: BorderRadius.circular(10),
    //         ),
    //         border: OutlineInputBorder(
    //           borderRadius: BorderRadius.circular(10),
    //         ),
    //       ),
    //     ),
    //   );
    //   actionBtn = TextButton(
    //       onPressed: onEnterEditing,
    //       child: const Icon(Icons.check, color: Colors.green)
    //   );
    // } else {
    //   textOrInput = Text(controller.text, style: commonStyles?.bodyStyle,);
    //   actionBtn = TextButton(
    //       onPressed: onEnterEditing,
    //       child: const Icon(Icons.edit_outlined, color: Colors.blueAccent)
    //   );
    // }

    // return Row(
    //   children: [
    //     textOrInput,
    //     const SizedBox(width: 8),
    //     actionBtn
    //   ],
    // );
     return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: editing ? _buildEditMode(commonStyles) : _buildViewMode(commonStyles),
    );
  }

    Widget _buildEditMode(CommonStyles? styles) {
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: _maxInputWidth),
          child: TextFormField(
            // ... 已有参数添加边框样式 ...
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: styles?.primaryColor ?? Colors.blueAccent,
                  width: _focusBorderWidth
                ),
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
            ),
          ),
        ),
        _buildActionButton(Icons.check, Colors.green, onQuitEditing)
      ],
    );
  }

  Widget _buildViewMode(CommonStyles? styles) {
    return Row(
      children: [
        Text(controller.text, style: styles?.bodyStyle),
        _buildActionButton(Icons.edit_outlined, styles?.primaryColor, onEnterEditing)
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color? color, VoidCallback action) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: action,
      splashRadius: 24,
      iconSize: _iconSize,
    );
  }
}


class InnerShadowBox extends StatelessWidget {
  // 新增默认参数
  static const _defaultRadius = 16.0;
  static const _shadowOpacity = 0.15;

  final Widget child;

  const InnerShadowBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(10), // 圆角
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.grey.withOpacity(0.5),
        //       spreadRadius: 2,
        //       blurRadius: 5,
        //       offset: const Offset(0, 3),
        //     ),
        //     const BoxShadow(
        //       color: Colors.white,
        //       spreadRadius: -4.0,
        //       blurRadius: 2.0,
        //     ),
        //   ],
        // ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_defaultRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_shadowOpacity),
              spreadRadius: 3,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
            const BoxShadow(
              color: Colors.white,
              spreadRadius: -6.0,
              blurRadius: 4.0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), // 圆角
          child: child,
        ),
    );
  }
}

class SelectImagesDialog extends StatefulWidget {
  final String? imageAssetPath;
  final String? imageUrl;
  final CommonStyles? commonStyles;
  const SelectImagesDialog({super.key, this.imageAssetPath, this.imageUrl, required this.commonStyles});

  @override
  State<SelectImagesDialog> createState() => _SelectImagesDialogState();
}

class _SelectImagesDialogState extends State<SelectImagesDialog> {
  late CommonStyles? commonStyles;
  String? imageUrl;
  String? imageAssetPath;

  @override
  void initState() {
    imageUrl = widget.imageUrl;
    imageAssetPath = widget.imageAssetPath;
    commonStyles = widget.commonStyles;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildSimpleActionDialog(
        context,
        title: "选项设置",
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {
                      doPickFile () {
                        pickImageFile().then((imgFile) {
                          if (imgFile != null) {
                            uploadFile(imgFile, FileType.image).then((url) {
                              setState(() {
                                imageUrl = url;
                                imageAssetPath = null;
                              });
                            }).catchError((err) { requestResultErrorHandler(context, error: err); return err;});
                          }
                        });
                      }
                      if (imageUrl != null || imageAssetPath != null) {
                        confirm(context, title: "确认", body: "已有图片，重新上传会覆盖已有的图片，确认要重新上传图片吗？", commonStyles: commonStyles,
                            onConfirm: (context) {
                              Navigator.pop(context);
                              doPickFile();
                            }
                        );
                      } else {
                        doPickFile();
                      }
                    },
                    child: Text("上传图片", style: commonStyles?.bodyStyle,)
                ),
                const SizedBox(width: 16,),
                ElevatedButton(
                    onPressed: () {
                      doSelectImage() {
                        showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog()).then((url) {
                          setState(() {
                            imageUrl = url;
                            imageAssetPath = null;
                          });
                        });
                      }
                      if (imageUrl != null || imageAssetPath != null) {
                        confirm(context, title: "确认", body: "选项已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                            onConfirm: (context) {
                              Navigator.pop(context);
                              doSelectImage();
                            }
                        );
                      } else {
                        doSelectImage();
                      }
                    },
                    child: Text("已上传的图片", style: commonStyles?.bodyStyle,)
                ),
                const SizedBox(width: 16,),
                ElevatedButton(
                    onPressed: () {
                      doSelectImage() {
                        showDialog<String>(context: context, builder: (context) => const SelectExistingImageDialog(isBuiltIn: true,)).then((path) {
                          setState(() {
                            imageAssetPath = path;
                            imageUrl = null;
                          });
                        });
                      }
                      if (imageUrl != null || imageAssetPath != null) {
                        confirm(context, title: "确认", body: "已有图片，重新选择图片会覆盖已有的图片，确认要重新选择图片吗？", commonStyles: commonStyles,
                            onConfirm: (context) {
                              Navigator.pop(context);
                              doSelectImage();
                            }
                        );
                      } else {
                        doSelectImage();
                      }
                    },
                    child: Text("系统内置图片", style: commonStyles?.bodyStyle,)
                ),
              ],
            ),
            const SizedBox(height: 16,),
            buildImagePreview(imageUrl: imageUrl, imageAssetPath: imageAssetPath, commonStyles: commonStyles),
            const SizedBox(height: 16,),
            imageUrl == null && imageAssetPath == null ? const SizedBox.shrink() : ElevatedButton(
              onPressed: () {
                setState(() {
                  imageUrl = null;
                  imageAssetPath = null;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.errorColor),
              child: Text("移除图片", style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onErrorColor), ),
            ),
          ],
        ),
        commonStyles: commonStyles,
        onConfirm: (context) {
          if ((imageUrl ?? imageAssetPath) != null) {
            Navigator.pop(context, {"imageUrl": imageUrl, "imageAssetPath": imageAssetPath});
          } else {
            toast(context, msg: "请至少设置一张图片。", btnText: "确认");
          }
        }
    );
  }
}

class SelectExistingImageDialog extends StatefulWidget {
  final bool isBuiltIn;
  const SelectExistingImageDialog({super.key, this.isBuiltIn = false});

  @override
  State<SelectExistingImageDialog> createState() => _SelectExistingImageDialogState();
}

class _SelectExistingImageDialogState extends State<SelectExistingImageDialog> with UseCommonStyles {
  Future<List<JsonObject>> futureImages = Future.value([]);
  JsonObject? selectedImage;
  ScrollController controller = ScrollController();

  @override
  void initState() {
    futureImages = widget.isBuiltIn ? getImageForQuestionSetting() : getUploadedImages();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);
    final mediaSize = MediaQuery.of(context).size;
    final title = widget.isBuiltIn ? "从系统内置图片中选择" : "从已上传的图片中选择";


    return buildSimpleActionDialog(context,
        title: title,
        body: FutureBuilder(
            future: futureImages,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<JsonObject> imageObjects = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: imageObjects.isEmpty ? Center(
                    child: Text("暂无数据", style: commonStyles?.hintTextStyle,),
                  ) : GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: mediaSize.width / (mediaSize.height * 1.4),
                    crossAxisCount: mediaSize.width > 1200 ? 5 : mediaSize.width > 800 ? 3 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 40,
                    children: imageObjects.map((e) => InkWell(
                      onTap: () {
                        setState(() {
                          selectedImage = e;
                        });
                      },
                      child: Builder(
                          builder: (context) {
                            Widget imageWidget = Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: !widget.isBuiltIn
                                          ? Image.network(e['url'],
                                              fit: BoxFit.contain,
                                            )
                                          : Image.asset(e['url'],
                                             fit: BoxFit.contain,
                                            ),
                                    ),
                                    Text(e['name'], style: commonStyles?.bodyStyle,)
                                  ],
                                ),
                              ),
                            );
                            if (selectedImage == e) {
                              return buildInnerShadowedBox(child: imageWidget);
                            } else {
                              return imageWidget;
                            }
                          }
                      ),
                    )).toList(),
                  ),
                );
              } else if (snapshot.hasError) {
                print(snapshot.error);
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  toast(context, msg: "网络错误，请重试", btnText: "确认");
                });
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                    const SizedBox(height: 16),
                    Text('读取中，请稍候', style: commonStyles?.hintTextStyle),
                  ],
                ),
              );
            }
        ),
        commonStyles: commonStyles,
        onConfirm: (context) {
          if (selectedImage != null) {
            Navigator.pop(context, selectedImage!['url']);
          }
        }
    );
  }
}
class SelectExistingAudioDialog extends StatefulWidget {
  const SelectExistingAudioDialog({super.key});

  @override
  State<SelectExistingAudioDialog> createState() => _SelectExistingAudioDialogState();
}

class _SelectExistingAudioDialogState extends State<SelectExistingAudioDialog> with UseCommonStyles {
  Future<List<JsonObject>> futureAudios = Future.value([]);
  JsonObject? selectedAudio;
  ScrollController controller = ScrollController();

  @override
  void initState() {
    futureAudios = getUploadedAudios();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);
    final mediaSize = MediaQuery.of(context).size;
    const title = "从已上传的音频文件中选择";


    return buildSimpleActionDialog(context,
        title: title,
        body: FutureBuilder(
            future: futureAudios,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<JsonObject> imageObjects = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: imageObjects.isEmpty ? Center(
                    child: Text("暂无数据", style: commonStyles?.hintTextStyle,),
                  ) : GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: mediaSize.width / (mediaSize.height * 1.4),
                    crossAxisCount: mediaSize.width > 1200 ? 5 : mediaSize.width > 800 ? 3 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 40,
                    children: imageObjects.map((e) => InkWell(
                      onTap: () {
                        setState(() {
                          selectedAudio = e;
                        });
                      },
                      child: Builder(
                          builder: (context) {
                            Widget imageWidget = Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: commonStyles?.primaryColor ?? Colors.blueAccent, width: 2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: SizedBox.expand(
                                          child: Icon(Icons.music_note, color: commonStyles?.primaryColor,)
                                        )
                                      ),
                                    ),
                                    Text(e['name'], style: commonStyles?.bodyStyle,)
                                  ],
                                ),
                              ),
                            );
                            if (selectedAudio == e) {
                              return buildInnerShadowedBox(child: imageWidget);
                            } else {
                              return imageWidget;
                            }
                          }
                      ),
                    )).toList(),
                  ),
                );
              } else if (snapshot.hasError) {
                print(snapshot.error);
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  toast(context, msg: "网络错误，请重试", btnText: "确认");
                });
              }

              return Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('读取中，请稍候', style: commonStyles?.hintTextStyle,),
                    ),
                  ],
                ),
              );
            }
        ),
        commonStyles: commonStyles,
        onConfirm: (context) {
          if (selectedAudio != null) {
            Navigator.pop(context, selectedAudio!['url']);
          }
        }
    );
  }
}