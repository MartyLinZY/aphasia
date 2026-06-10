import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:web/web.dart' as web;

mixin AudioRecorderMixin {
  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) {
    return recorder.start(config, path: '');
  }

  Future<void> recordStream(AudioRecorder recorder, RecordConfig config,
    {required void Function(List<int> data) onStop}) async {
    final b = <Uint8List>[];
    final stream = await recorder.startStream(config);
    final List<int> bytes = [];

    stream.listen(
      (data) => b.add(data),
      onDone: () {
        for (var uint8List in b) {
          bytes.addAll(uint8List);
        }
        onStop(bytes);
      },
    );
  }

  void downloadWebData(String path) {
    final anchor = web.HTMLAnchorElement()
      ..href = path
      ..style.display = 'none'
      ..download = 'audio.wav';
    web.document.body!.appendChild(anchor);
    anchor.click();
    web.document.body!.removeChild(anchor);
  }
}
