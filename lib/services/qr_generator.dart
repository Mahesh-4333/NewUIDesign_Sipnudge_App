import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

Future<File> generateQrImage({
  required String data,
  required Color color,
  required String fileName,
}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    color: color,
    emptyColor: Colors.white,
  );

  final image = await painter.toImage(300);
  final byteData = await image.toByteData(format: ImageByteFormat.png);

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName.png');

  await file.writeAsBytes(byteData!.buffer.asUint8List());
  return file;
}
