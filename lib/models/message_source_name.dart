/*
 * 消息来源名称模型 — 信息中心二级来源枚举
 * 拆分来源名称枚举，保持 MessageItem 主模型文件低于仓库行数上限
 * @Project : SSPU-all-in-one
 * @File : message_source_name.dart
 * @Author : Qintsg
 * @Date : 2026-05-11
 */

part of 'message_item.dart';

/// 消息来源名称（tag2）
enum MessageSourceName {
  /// 信息公开网
  infoDisclosure('信息公开网'),

  /// 教务处
  jwc('教务处'),

  /// 信息技术中心
  itc('信息技术中心'),

  /// 学校官网（通知公告/学术活动）
  sspuOfficial('学校官网'),

  /// 体育部
  sports('体育部'),

  /// 保卫处
  securityDept('保卫处'),

  /// 基建处
  construction('基建处'),

  /// 新闻网
  newsCenter('新闻网'),

  /// 学生处
  studentAffairs('学生处'),

  /// 后勤服务中心
  logisticsCenter('后勤服务中心'),

  /// 外国留学生事务办公室
  foreignStudentOffice('外国留学生事务办公室'),

  /// 国际交流处
  intlExchangeOffice('国际交流处'),

  /// 招生办
  admissionsOffice('招生办'),

  /// 人事处
  hrOffice('人事处'),

  /// 科研处
  researchOffice('科研处'),

  /// 校工会
  union('校工会'),

  /// 党委组织部
  partyOrgDept('党委组织部'),

  /// 党委统战部
  unitedFrontDept('党委统战部'),

  /// 党委办公室
  partyOffice('党委办公室'),

  /// 校团委
  youthLeague('校团委'),

  /// 资产与实验管理处
  assetsLabOffice('资产与实验管理处'),

  /// 计算机与信息工程学院
  collegeCs('计算机与信息工程学院'),

  /// 智能制造与控制工程学院
  collegeIm('智能制造与控制工程学院'),

  /// 资源与环境工程学院
  collegeRe('资源与环境工程学院'),

  /// 能源与材料学院
  collegeEm('能源与材料学院'),

  /// 集成电路学院
  collegeIc('集成电路学院'),

  /// 智能医学与健康工程学院
  collegeImhe('智能医学与健康工程学院'),

  /// 经济与管理学院
  collegeEcon('经济与管理学院'),

  /// 语言与文化传播学院
  collegeLang('语言与文化传播学院'),

  /// 数理与统计学院
  collegeMath('数理与统计学院'),

  /// 艺术与设计学院
  collegeArt('艺术与设计学院'),

  /// 职业技术教师教育学院
  collegeVte('职业技术教师教育学院'),

  /// 职业技术学院
  collegeVt('职业技术学院'),

  /// 马克思主义学院
  collegeMarx('马克思主义学院'),

  /// 继续教育学院
  collegeCe('继续教育学院'),

  /// 艺术教育中心
  centerArtEdu('艺术教育中心'),

  /// 国际教育中心
  centerIntl('国际教育中心'),

  /// 创新创业教育中心
  centerInnov('创新创业教育中心'),

  /// 工程训练与创新教育中心
  centerTraining('工程训练与创新教育中心'),

  /// 研究生处
  graduate('研究生处'),

  /// 图书馆
  libCenter('图书馆'),

  /// 微信推文来源，用于聚合公众号平台文章
  wechatPublicPlaceholder('微信推文'),

  /// 微信服务号来源，仅用于兼容历史缓存记录
  wechatServicePlaceholder('微信服务号');

  const MessageSourceName(this.label);

  /// 显示名称
  final String label;
}
