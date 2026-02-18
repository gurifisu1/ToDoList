import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

void saveFileWeb(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> saveFileNative(Uint8List bytes, String fileName) async {
  saveFileWeb(bytes, fileName);
}
