import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void saveFileWeb(Uint8List bytes, String fileName) {
  throw UnsupportedError('Web save not supported on native platform');
}

Future<void> saveFileNative(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: fileName);
}
