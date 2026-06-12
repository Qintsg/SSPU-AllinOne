/*
 * 校历文件操作 IO 实现 — 下载 PDF、写入抽取文本并调用 pdfrx 抽取 PDF 文本
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_file_ops_io.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app_data_directory_service.dart';
import 'http_service.dart';

/// 从 PDF 文件抽取全文。
Future<String> extractAcademicCalendarPdfText(String pdfFilePath) async {
  await pdfrxFlutterInitialize();
  final document = await PdfDocument.openFile(pdfFilePath);
  final buffer = StringBuffer();
  try {
    for (final page in document.pages) {
      final text = await page.loadText();
      final fullText = text?.fullText.trim();
      if (fullText == null || fullText.isEmpty) continue;
      buffer
        ..writeln(fullText)
        ..writeln();
    }
  } finally {
    await document.dispose();
  }
  return buffer.toString().trim();
}

/// 下载校历 PDF 到本地缓存目录。
Future<String> downloadAcademicCalendarPdf(
  HttpService http,
  String pdfUrl, {
  required int schoolYearStart,
}) async {
  final directoryPath = await AppDataDirectoryService.ensureDirectoryPath(
    'academic_calendars${Platform.pathSeparator}pdf',
  );
  final filePath =
      '$directoryPath${Platform.pathSeparator}$schoolYearStart.pdf';
  await http.download(pdfUrl, filePath, cancelToken: CancelToken());
  return filePath;
}

/// 写入 PDF 抽取文本。
Future<String> writeAcademicCalendarRawText(
  String rawText, {
  required int schoolYearStart,
}) async {
  final directoryPath = await AppDataDirectoryService.ensureDirectoryPath(
    'academic_calendars${Platform.pathSeparator}text',
  );
  final filePath =
      '$directoryPath${Platform.pathSeparator}$schoolYearStart.txt';
  await File(filePath).writeAsString(rawText);
  return filePath;
}
