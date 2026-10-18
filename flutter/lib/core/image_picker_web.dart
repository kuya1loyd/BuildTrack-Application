// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageAsDataUrlImpl() {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/gif'
    ..multiple = false;

  void cleanUp() {
    uploadInput.remove();
  }

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      cleanUp();
      return;
    }

    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
      cleanUp();
    });

    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      cleanUp();
    });

    reader.readAsDataUrl(file);
  });

  uploadInput.click();
  return completer.future;
}
