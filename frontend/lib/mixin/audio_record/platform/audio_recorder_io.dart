import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

mixin AudioRecorderMixin {
  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await _getPath();

    await recorder.start(config, path: path);
  }

  Future<void> recordStream(AudioRecorder recorder, RecordConfig config, {required void Function(List<int> data) onStop}) async {
    final path = await _getPath();

    final file = File(path);

    final stream = await recorder.startStream(config);
    final List<int> bytes = [];

    stream.listen(
          (data) {
        // ignore: avoid_print
        // print(
        //   recorder.convertBytesToInt16(Uint8List.fromList(data)),
        // );
        // file.writeAsBytesSync(data, mode: FileMode.append);
          bytes.addAll(data);
      },
      // ignore: avoid_print
      onDone: () {
        // ignore: avoid_print
        onStop(bytes);
        // print('End of stream. File written to $path.');
      },
    );
  }

  void downloadWebData(String path) {}

  Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }
}