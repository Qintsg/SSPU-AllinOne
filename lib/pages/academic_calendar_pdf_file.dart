/*
 * 校历 PDF 文件能力出口 — 根据平台判断本地 PDF 是否可用
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_file.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

export 'academic_calendar_pdf_file_stub.dart'
    if (dart.library.io) 'academic_calendar_pdf_file_io.dart';
