import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../utils/http/http_common.dart';

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
