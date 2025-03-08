import 'dart:typed_data';

import 'package:aphasia_recovery/enum/system.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


Future<WrappedFile?> pickFile(FileType type) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type
  );

  if (result != null) {
    PlatformFile file = result.files.first;

    // debugPrint(file.name);
    // debugPrint(file.size.toString());
    // if (getPlatformType() != PlatformType.web) {
    //   debugPrint(file.path);
    // }

    return WrappedFile(file: file);
  }

  return null;
}

Future<WrappedFile?> pickAudioFile() async {
  return pickFile(FileType.audio);
}

Future<WrappedFile?> pickImageFile() async {
  return pickFile(FileType.image);
}

class WrappedFile {
  PlatformFile file;
  WrappedFile({required this.file});

  String get name => file.name;

  int get size => file.size;

  String? get path => file.path;

  Uint8List? get bytes => file.bytes;
}