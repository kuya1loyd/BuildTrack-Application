import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart';

Future<String?> pickImageAsDataUrl() => pickImageAsDataUrlImpl();
