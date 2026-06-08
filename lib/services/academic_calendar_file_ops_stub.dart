/*
 * 校历文件操作降级实现 — Web 等无本地文件平台只保留 URL 与结构化缓存
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_file_ops_stub.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'http_service.dart';

/// 从 PDF 文件抽取全文。
Future<String> extractAcademicCalendarPdfText(String pdfFilePath) async {
  throw UnsupportedError('当前平台不支持本地 PDF 文本抽取');
}

/// 下载校历 PDF 到本地缓存目录。
Future<String> downloadAcademicCalendarPdf(
  HttpService http,
  String pdfUrl, {
  required int schoolYearStart,
}) async {
  throw UnsupportedError('当前平台不支持本地 PDF 缓存');
}

/// 写入 PDF 抽取文本。
Future<String> writeAcademicCalendarRawText(
  String rawText, {
  required int schoolYearStart,
}) async {
  throw UnsupportedError('当前平台不支持本地文本缓存');
}
