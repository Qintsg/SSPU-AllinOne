/*
 * 本专科教务系统个人信息模型
 * @Project : SSPU-AllinOne
 * @File : profile.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 本专科教务系统个人基本信息。
class AcademicEamsProfile {
  const AcademicEamsProfile({
    required this.name,
    required this.studentId,
    required this.department,
    required this.major,
    required this.className,
    required this.gender,
    required this.studyLength,
    required this.educationLevel,
    required this.rawFields,
  });

  /// 学生姓名。
  final String? name;

  /// 学号。
  final String? studentId;

  /// 院系名称。
  final String? department;

  /// 专业名称。
  final String? major;

  /// 班级名称。
  final String? className;

  /// 性别。
  final String? gender;

  /// 学制。
  final String? studyLength;

  /// 学历层次。
  final String? educationLevel;

  /// 原始字段集合，供页面结构变化时回退展示。
  final Map<String, String> rawFields;

  /// 从 JSON 恢复个人基本信息。
  factory AcademicEamsProfile.fromJson(Map<String, dynamic> json) {
    return AcademicEamsProfile(
      name: json['name'] as String?,
      studentId: json['studentId'] as String?,
      department: json['department'] as String?,
      major: json['major'] as String?,
      className: json['className'] as String?,
      gender: json['gender'] as String?,
      studyLength: json['studyLength'] as String?,
      educationLevel: json['educationLevel'] as String?,
      rawFields: const {},
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'studentId': studentId,
      'department': department,
      'major': major,
      'className': className,
      'gender': gender,
      'studyLength': studyLength,
      'educationLevel': educationLevel,
    };
  }

  /// 转换为普通缓存可持久化 JSON，移除学籍明文字段。
  Map<String, dynamic> toPublicCacheJson() {
    return {'hasProfile': hasAnyValue};
  }

  /// 是否至少解析出一个核心字段。
  bool get hasAnyValue {
    return [
      name,
      studentId,
      department,
      major,
      className,
      gender,
      studyLength,
      educationLevel,
    ].any((value) => value != null && value.trim().isNotEmpty);
  }

  /// 首页学籍卡片所需字段是否完整。
  bool get hasHomeSummary {
    return [
      name,
      studentId,
      department,
      major,
      className,
    ].every((value) => value != null && value.trim().isNotEmpty);
  }
}
