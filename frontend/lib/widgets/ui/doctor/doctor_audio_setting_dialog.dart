import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/utils/io/file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../utils/http/http_common.dart';
import '../common/common.dart';
import 'doctor_generate_audio_from_text_dialog.dart';

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
