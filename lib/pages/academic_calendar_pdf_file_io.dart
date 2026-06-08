/*
 * 校历 PDF 文件能力 IO 实现 — 检查本地 PDF 文件存在性
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_file_io.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:io';

/// 判断本地 PDF 是否存在。
bool academicCalendarPdfFileExists(String? path) {
  return path != null && path.isNotEmpty && File(path).existsSync();
}
