import 'dart:typed_data';

void saveFileWeb(Uint8List bytes, String fileName) {
  throw UnsupportedError('Web not supported on this platform');
}

Future<void> saveFileNative(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Native not supported on this platform');
}
