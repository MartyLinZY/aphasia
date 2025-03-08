
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/utils/io/file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../utils/http/http_common.dart';
import '../common/common.dart';

class AudioSettingDialog extends StatefulWidget {
  final String? uploadedAudioUrl;

  const AudioSettingDialog({
    super.key,
    this.uploadedAudioUrl,
  });

  @override
  State<AudioSettingDialog> createState() => _AudioSettingDialogState();
}

class _AudioSettingDialogState extends State<AudioSettingDialog>
    with UseCommonStyles, AudioPlayerSetting {
  WrappedFile? file;
  String? uploadedAudioUrl;

  void resetFileState() {
    file = null;
    uploadedAudioUrl = null;
  }

  @override
  void initState() {
    super.initState();

    setStateProxy = setState;
    initPlayStateSubscription();

    uploadedAudioUrl = widget.uploadedAudioUrl;
    if (uploadedAudioUrl != null) {
      setupPlayer(uploadedAudioUrl!);
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    disposePlayStateSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    return buildSimpleActionDialog(context,
        title: "设置音频",
        body: Column(
          children: [
            _buildAudioActions(context),
            const Divider(),
            _buildAudioInfo(context),
          ],
        ),
        commonStyles: commonStyles, onConfirm: (context) {
      Navigator.pop(context, uploadedAudioUrl);
    });
  }

  _buildAudioActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {
            doPickFile() {
              stop();
              pickAudioFile().then((pickedFile) {
                if (pickedFile != null) {
                  uploadFile(pickedFile, FileType.audio).then((url) {
                    setState(() {
                      file = pickedFile;
                      uploadedAudioUrl = url;
                      setupPlayer(url);
                    });
                  }).catchError((err) {
                    requestResultErrorHandler(context, error: err);
                    return err;
                  });
                }
              });
            }

            if (uploadedAudioUrl != null) {
              confirm(context,
                  title: "确认",
                  body: "重新上传会覆盖已有音频文件，确认要重新上传吗？",
                  commonStyles: commonStyles, onConfirm: (context) {
                Navigator.pop(context);
                doPickFile();
              });
            } else {
              doPickFile();
            }
          },
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6.0)),
          child: Text(
            "选择音频文件",
            style: commonStyles?.bodyStyle,
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        ElevatedButton(
          onPressed: () {
            showExistingAudioDialog() {
              stop();
              showDialog<String>(
                  context: context,
                  builder: (context) {
                    return const SelectExistingAudioDialog();
                  }).then((url) {
                if (url != null) {
                  setState(() {
                    file = null; // 重置文件
                    uploadedAudioUrl = url;
                    setupPlayer(url);
                  });
                }
              });
            }
            if (uploadedAudioUrl != null) {
              confirm(context,
                  title: "确认",
                  body: "选择其他音频会覆盖已有音频文件，确认要重新上传吗？",
                  commonStyles: commonStyles, onConfirm: (context) {
                    Navigator.pop(context);
                    showExistingAudioDialog();
                  });
            } else {
              showExistingAudioDialog();
            }
          },
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6.0)),
          child: Text(
            "选择已上传音频文件",
            style: commonStyles?.bodyStyle,
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        // ElevatedButton(
        //     onPressed: () {
        //       doPickFile() {
        //         pickFile().then((pickedFile) {
        //           if (pickedFile != null) {
        //             setState(() {
        //               file = pickedFile;
        //             });
        //           }
        //         });
        //       }
        //       if (file != null) {
        //         confirm(
        //             context, title: "确认",
        //             body: "重新上传会覆盖已有音频文件，确认要重新上传吗？",
        //             commonStyles: commonStyles,
        //             onConfirm: (context) {
        //               Navigator.pop(context);
        //               doPickFile();
        //             }
        //         );
        //       } else {
        //         doPickFile();
        //       }
        //     },
        //     style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6.0)),
        //     child: Text("现场录制", style: commonStyles?.bodyStyle,)
        // ),
        // const SizedBox(width: 16,),
        ElevatedButton(
            onPressed: () {
              showGenerateAudioDialog() {
                stop();
                showDialog<String>(
                    context: context,
                    builder: (context) {
                      return const GenerateAudioFromTextDialog();
                    }).then((url) {
                  if (url != null) {
                    setState(() {
                      file = null; // 重置文件
                      uploadedAudioUrl = url;
                      setupPlayer(url);
                    });
                  }
                });
              }

              if (uploadedAudioUrl != null) {
                confirm(context,
                    title: "确认",
                    body: "生成音频后会覆盖已有音频，确认要继续生成音频吗？",
                    commonStyles: commonStyles, onConfirm: (context) {
                  Navigator.pop(context);
                  showGenerateAudioDialog();
                });
              } else {
                showGenerateAudioDialog();
              }
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6.0)),
            child: Text(
              "输入文本生成录音",
              style: commonStyles?.bodyStyle,
            )),
      ],
    );
  }

  Widget _buildAudioInfo(BuildContext context) {
    var columnChildren = <Widget>[];

    if (file != null) {
      columnChildren.add(Text(
        "文件名：${file!.name}",
        style: commonStyles?.bodyStyle,
      ));
    }

    if (uploadedAudioUrl != null) {
      if (columnChildren.isNotEmpty) {
        columnChildren.add(const SizedBox(
          height: 16,
        ));
      }

      columnChildren.add(Row(
        children: [
          Text(
            "音频预览：",
            style: commonStyles?.bodyStyle,
          ),
          _buildPlayer(),
        ],
      ));
    }

    return columnChildren.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columnChildren,
          );
  }

  Widget _buildPlayer() {
    Widget playBtn;

    if (isPlaying) {
      playBtn = IconButton(
        key: const Key('play_btn'),
        onPressed: pause,
        icon: const Icon(Icons.pause),
        iconSize: 24,
        color: commonStyles?.primaryColor,
      );
    } else {
      playBtn = IconButton(
        key: const Key('pause_btn'),
        onPressed: isPlayerDisposed ? null : play,
        icon: const Icon(Icons.play_arrow),
        iconSize: 24,
        color: commonStyles?.primaryColor,
      );
    }

    return Column(
      children: [
        Row(
          children: [
            playBtn,
            IconButton(
              key: const Key('stop_btn'),
              onPressed: isPlaying || isPaused ? stop : null,
              icon: const Icon(Icons.stop),
              iconSize: 24,
              color: commonStyles?.primaryColor,
            )
          ],
        ),
        Slider(
          onChanged: (value) {
            final duration = audioDuration;
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (playPosition != null &&
                  audioDuration != null &&
                  playPosition!.inMilliseconds > 0 &&
                  playPosition!.inMilliseconds < audioDuration!.inMilliseconds)
              ? playPosition!.inMilliseconds / audioDuration!.inMilliseconds
              : 0.0,
        ),
        Text(
          playPosition != null
              ? '$positionText / $durationText'
              : audioDuration != null
                  ? durationText
                  : '',
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }
}

class GenerateAudioFromTextDialog extends StatefulWidget {
  const GenerateAudioFromTextDialog({super.key});

  @override
  State<GenerateAudioFromTextDialog> createState() =>
      _GenerateAudioFromTextDialogState();
}

class _GenerateAudioFromTextDialogState
    extends State<GenerateAudioFromTextDialog> with UseCommonStyles {
  TextEditingController textCtrl = TextEditingController();

  bool generating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    Widget body;
    if (!generating) {
      body = Row(
        children: [
          Text(
            "输入文本：",
            style: commonStyles?.bodyStyle,
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 100),
            child: TextField(
              controller: textCtrl,
              maxLength: 200,
            ),
          )
        ],
      );
    } else {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '生成中，请稍候',
                style: commonStyles!.hintTextStyle,
              ),
            ),
          ],
        ),
      );
    }

    return buildSimpleActionDialog(
      context,
      title: "生成音频",
      body: body,
      commonStyles: commonStyles,
      onConfirm: generating
          ? (context) {}
          : (context) {
              setState(() {
                generating = true;
                generatedAudioUrl(textCtrl.text)
                    .then((url) => Navigator.pop(context, url))
                    .catchError((err) {
                  requestResultErrorHandler(context, error: err);
                  return err;
                });
              });
            },
      onCancel: generating ? (context) {} : null,
    );
  }
}

class HintRuleEditDialog extends StatefulWidget {
  final Question question;
  final HintRule? hintRule;

  const HintRuleEditDialog({super.key, required this.question, this.hintRule});

  @override
  State<HintRuleEditDialog> createState() => _HintRuleEditDialogState();
}

class _HintRuleEditDialogState extends State<HintRuleEditDialog>
    with UseCommonStyles, AudioPlayerSetting, TextFieldCommonValidators, StateWithTextFields
    implements ResettableState {
  late Question currQuestion;
  late HintRule hintRule;

  String? audioUrl;
  String? imageUrl;
  String? imageAssetPath;

  String? hintTextValidator(String? value) {
    return null;
  }

  String? adjustValueValidator(String? value) {
    String? errMsg = notEmptyValidator("分值")(value);
    errMsg ??= needGreaterThanOrEqualDoubleValidator(0)(value);
    return errMsg;
  }

  String? scoreLowBoundValidator(String? value) {
    String? errMsg = notEmptyValidator("触发分数下界")(value);
    double? highBound =
        double.tryParse(fieldsSetting['scoreHighBound']!.ctrl.text);
    if (highBound != null) {
      errMsg ??= needSmallerThanOrEqualDoubleValidator(highBound)(value);
    }
    return errMsg;
  }

  String? scoreHighBoundValidator(String? value) {
    String? errMsg = notEmptyValidator("触发分数上界")(value);
    double? lowBound =
        double.tryParse(fieldsSetting['scoreLowBound']!.ctrl.text);
    if (lowBound != null) {
      errMsg ??= needGreaterThanOrEqualDoubleValidator(lowBound)(value);
    }
    return errMsg;
  }

  @override
  void initFieldSettings() {
    fieldsSetting['hintText'] = FieldSetting(
      key: GlobalKey<FormFieldState>(
          debugLabel: "question hint rule hintText key"),
      ctrl: TextEditingController(),
      validator: hintTextValidator,
      reset: () =>
          fieldsSetting['hintText']!.ctrl.text = hintRule.hintText ?? "",
      applyToModel: () =>
          hintRule.hintText = fieldsSetting['hintText']!.ctrl.text,
    );
    // fieldsSetting['adjustValue'] = FieldSetting(
    //   key: GlobalKey<FormFieldState>(
    //       debugLabel: "question hint rule adjustValue key"),
    //   ctrl: TextEditingController(),
    //   validator: adjustValueValidator,
    //   reset: () => fieldsSetting['adjustValue']!.ctrl.text =
    //       hintRule.adjustValue.toString(),
    //   applyToModel: () => hintRule.adjustValue =
    //       double.parse(fieldsSetting['adjustValue']!.ctrl.text),
    // );

    fieldsSetting['scoreLowBound'] = FieldSetting(
      key: GlobalKey<FormFieldState>(
          debugLabel: "question hint rule scoreLowBound key"),
      ctrl: TextEditingController(),
      validator: scoreLowBoundValidator,
      reset: () => fieldsSetting['scoreLowBound']!.ctrl.text =
          hintRule.scoreLowBound.toString(),
      applyToModel: () => hintRule.scoreLowBound =
          double.parse(fieldsSetting['scoreLowBound']!.ctrl.text),
    );

    fieldsSetting['scoreHighBound'] = FieldSetting(
      key: GlobalKey<FormFieldState>(
          debugLabel: "question hint rule scoreHighBound key"),
      ctrl: TextEditingController(),
      validator: scoreHighBoundValidator,
      reset: () => fieldsSetting['scoreHighBound']!.ctrl.text =
          hintRule.scoreHighBound.toString(),
      applyToModel: () => hintRule.scoreHighBound =
          double.parse(fieldsSetting['scoreHighBound']!.ctrl.text),
    );
  }

  @override
  bool applyFieldsChangesToModel() {
    if (validateAllFields()) {
      fieldsSetting.forEach((key, value) => value.applyToModel());
      return true;
    }
    return false;
  }

  @override
  void resetAllFields() {
    fieldsSetting.forEach((key, value) => value.reset());
  }

  @override
  bool validateAllFields() {
    return fieldsSetting.entries
        .map((e) => e.value.key.currentState?.validate() ?? true)
        .fold(true, (prev, valid) => prev && valid);
  }

  @override
  void resetState() {
    currQuestion = widget.question;
    hintRule = widget.hintRule ?? HintRule();

    imageUrl = hintRule.hintImageUrl;
    imageAssetPath = hintRule.hintImageAssetPath;
    audioUrl = hintRule.hintAudioUrl;
    if (audioUrl != null) {
      setupPlayer(audioUrl!);
    }

    resetAllFields();
  }

  @override
  void initState() {
    super.initState();

    setStateProxy = setState;
    initPlayStateSubscription();

    initFieldSettings();

    resetState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    disposePlayStateSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    return buildSimpleActionDialog(context,
        title: "编辑提示规则",
        body: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInputFormField(
                  "提示文本：",
                  fieldsSetting['hintText']!.key,
                  fieldsSetting['hintText']!.ctrl,
                  fieldsSetting['hintText']!.validator,
                  width: 200,
                  commonStyles: commonStyles),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Text(
                    "提示音频：",
                    style: commonStyles?.bodyStyle,
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => AudioSettingDialog(
                                uploadedAudioUrl: audioUrl,
                              )).then((url) {
                        setState(() {
                          if (url != null) {
                            setState(() {
                              audioUrl = url;
                              setupPlayer(url);
                            });
                          }
                        });
                      });
                    },
                    child: Text(
                      "设置",
                      style: commonStyles?.bodyStyle,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  audioUrl == null
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          onPressed: () {
                            confirm(context,
                                title: "确认",
                                body: "确认要删除已经设置的音频吗？",
                                commonStyles: commonStyles, onConfirm: (context) {
                              Navigator.pop(context);
                              setState(() {
                                audioUrl = null;
                              });
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: commonStyles?.errorColor),
                          child: Text(
                            "清除已设置音频",
                            style: commonStyles?.bodyStyle
                                ?.copyWith(color: commonStyles?.onErrorColor),
                          ),
                        )
                ],
              ),
              audioUrl == null
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        Text(
                          "音频预览：",
                          style: commonStyles?.bodyStyle,
                        ),
                        buildPlayer(commonStyles: commonStyles),
                      ],
                    ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Text(
                    "提示图片（不设置则默认用题干图片提示）：",
                    style: commonStyles?.bodyStyle,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => SelectImagesDialog(
                                imageUrl: imageUrl,
                                imageAssetPath: imageAssetPath,
                                commonStyles: commonStyles,
                              )).then((map) {
                        setState(() {
                          if (map != null) {
                            setState(() {
                              imageUrl = map['imageUrl'];
                              imageAssetPath = map['imageAssetPath'];
                            });
                          }
                        });
                      });
                    },
                    child: Text(
                      "设置",
                      style: commonStyles?.bodyStyle,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  (imageUrl ?? imageAssetPath) == null
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          onPressed: () {
                            confirm(context,
                                title: "确认",
                                body: "确认要删除已经设置的图片吗？",
                                commonStyles: commonStyles, onConfirm: (context) {
                              Navigator.pop(context);
                              setState(() {
                                imageUrl = null;
                                imageAssetPath = null;
                              });
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: commonStyles?.errorColor),
                          child: Text(
                            "清除已设置图片",
                            style: commonStyles?.bodyStyle
                                ?.copyWith(color: commonStyles?.onErrorColor),
                          ),
                        )
                ],
              ),
              (imageAssetPath ?? imageUrl) == null
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        Text(
                          "图片预览：",
                          style: commonStyles?.bodyStyle,
                        ),
                        buildImagePreview(
                            imageUrl: imageUrl,
                            imageAssetPath: imageAssetPath,
                            commonStyles: commonStyles),
                      ],
                    ),
              const SizedBox(
                height: 16,
              ),
              // buildInputFormField(
              //     "提示后正答扣分值：",
              //     fieldsSetting['adjustValue']!.key,
              //     fieldsSetting['adjustValue']!.ctrl,
              //     fieldsSetting['adjustValue']!.validator,
              //     commonStyles: commonStyles),
              // const SizedBox(
              //   height: 16,
              // ),
              buildInputFormField(
                  "触发分数下界：",
                  fieldsSetting['scoreLowBound']!.key,
                  fieldsSetting['scoreLowBound']!.ctrl,
                  fieldsSetting['scoreLowBound']!.validator,
                  commonStyles: commonStyles),
              const SizedBox(
                height: 16,
              ),
              buildInputFormField(
                  "触发分数上界：",
                  fieldsSetting['scoreHighBound']!.key,
                  fieldsSetting['scoreHighBound']!.ctrl,
                  fieldsSetting['scoreHighBound']!.validator,
                  commonStyles: commonStyles),
            ],
          ),
        ),
        commonStyles: commonStyles, onConfirm: (context) {
      if ((audioUrl == null &&
          imageAssetPath == null &&
          imageUrl == null &&
          fieldsSetting['hintText']!.ctrl.text == "")) {
        toast(context, msg: "请至少在提示文本，提示音频和提示图片中选择一个设置。", btnText: "确认");
        return;
      }

      if (applyFieldsChangesToModel()) {
        Navigator.pop(
            context,
            HintRule(
                hintText: fieldsSetting['hintText']!.ctrl.text,
                hintImageUrl: imageUrl,
                hintAudioUrl: audioUrl,
                hintImageAssetPath: imageAssetPath,
                scoreHighBound: hintRule.scoreHighBound,
                scoreLowBound: hintRule.scoreLowBound,
                scoreAdjustType: hintRule.scoreAdjustType,
                // adjustValue: hintRule.adjustValue
            ));
      }
    });
  }
}
