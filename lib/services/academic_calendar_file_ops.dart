/*
 * 校历文件操作出口 — 根据平台选择本地 PDF 缓存与文本抽取实现
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_file_ops.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

export 'academic_calendar_file_ops_stub.dart'
    if (dart.library.io) 'academic_calendar_file_ops_io.dart';
