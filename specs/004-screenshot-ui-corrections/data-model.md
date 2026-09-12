# Data Model

- `AcademicGradeSnapshot`: 跨当前与历史记录去重后计算全量 GPA、学分和成绩数。
- `AcademicTermChoice`: 学年与季节；夏季学期考试可关联上一教学学期补考。
- `EmailMessageSnapshot`: 邮件元数据、正文和附件；空正文属于合法空态。
