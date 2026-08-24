/*
 * 本专科教务成绩查询流程 — 拉取当前学期与历史成绩并聚合为可缓存快照
 * @Project : SSPU-AllinOne
 * @File : academic_eams_grade_flow.dart
 * @Author : Qintsg
 * @Date : 2026-06-14
 */

part of 'academic_eams_service.dart';

extension _AcademicEamsGradeFlow on AcademicEamsService {
  /// 拉取并聚合成绩查询结果。
  ///
  /// 一次性读取当前学期成绩页与历史成绩页并合并为成绩快照；学期切换交由
  /// 前端按学年学期分组完成，无需逐学期重复请求。
  ///
  /// :param homeSnapshot: 已解析的 EAMS 首页快照，用于兜底来源地址。
  /// :param featureUris: 已发现的只读功能入口地址。
  /// :param featureSnapshots: 复用的功能页快照缓存表。
  /// :param warnings: 流程中累积的降级原因。
  /// :param campusNetworkStatus: 当前校园网状态，用于结果提示。
  /// :returns: 含成绩快照的查询结果。
  Future<AcademicEamsQueryResult> _buildGradesOnlyResult({
    required AcademicEamsHttpSnapshot homeSnapshot,
    required Map<_AcademicFeature, Uri> featureUris,
    required Map<_AcademicFeature, AcademicEamsHttpSnapshot> featureSnapshots,
    required List<String> warnings,
    required CampusNetworkStatus? campusNetworkStatus,
  }) async {
    await _fetchOptionalFeature(
      _AcademicFeature.gradeCurrent,
      featureUris,
      featureSnapshots,
      warnings,
    );
    await _fetchOptionalFeature(
      _AcademicFeature.gradeHistory,
      featureUris,
      featureSnapshots,
      warnings,
    );
    // 当前成绩为壳页，需 followup 到 person!search.action；历史成绩页直接解析。
    await _resolveGradeFeatureSnapshot(
      _AcademicFeature.gradeCurrent,
      featureSnapshots,
      warnings,
    );
    await _resolveGradeFeatureSnapshot(
      _AcademicFeature.gradeHistory,
      featureSnapshots,
      warnings,
    );

    final hasGradePages =
        featureSnapshots.containsKey(_AcademicFeature.gradeCurrent) ||
        featureSnapshots.containsKey(_AcademicFeature.gradeHistory);
    final grades = _parseGrades(
      featureSnapshots[_AcademicFeature.gradeCurrent],
      featureSnapshots[_AcademicFeature.gradeHistory],
    );

    if (grades == null && !hasGradePages) {
      return _buildResult(
        AcademicEamsQueryStatus.readOnlyEntryUnavailable,
        message: '未识别到成绩查询入口',
        detail: warnings.isEmpty
            ? 'EAMS 只读菜单中没有可验证的成绩查询入口。'
            : warnings.join('；'),
        finalUri: homeSnapshot.finalUri,
        campusNetworkStatus: campusNetworkStatus,
      );
    }

    // 页面可访问但解析不到记录时，按空成绩快照降级展示而非报失败。
    final sourceUri =
        featureSnapshots[_AcademicFeature.gradeHistory]?.finalUri ??
        featureSnapshots[_AcademicFeature.gradeCurrent]?.finalUri ??
        homeSnapshot.finalUri;
    final resolvedGrades =
        grades ??
        AcademicGradeSnapshot(
          currentTermRecords: const [],
          historyRecords: const [],
          fetchedAt: DateTime.now(),
          sourceUri: sourceUri,
        );

    final snapshot = AcademicEamsSnapshot(
      fetchedAt: resolvedGrades.fetchedAt,
      sourceUri: resolvedGrades.sourceUri,
      warnings: List.unmodifiable(warnings),
      hasCourseOfferingEntry: featureUris.containsKey(
        _AcademicFeature.courseOfferingsEntry,
      ),
      hasFreeClassroomEntry: featureUris.containsKey(
        _AcademicFeature.freeClassroomEntry,
      ),
      grades: resolvedGrades,
    );

    final hasRecords = resolvedGrades.allRecords.isNotEmpty;
    return _buildResult(
      warnings.isEmpty
          ? AcademicEamsQueryStatus.success
          : AcademicEamsQueryStatus.partialSuccess,
      message: hasRecords ? '成绩读取成功' : '暂无可展示的成绩',
      detail: hasRecords ? '已读取当前学期与历史成绩，可在详情页按学期查看。' : '成绩查询已执行，但未发现可展示的成绩记录。',
      finalUri: resolvedGrades.sourceUri,
      campusNetworkStatus: campusNetworkStatus,
      snapshot: snapshot,
    );
  }

  /// 解析单个成绩功能页快照，处理壳页 followup 与降级移除。
  ///
  /// :param feature: 成绩功能枚举（当前成绩或历史成绩）。
  /// :param featureSnapshots: 功能页快照缓存表。
  /// :param warnings: 流程中累积的降级原因。
  /// :returns: 无返回值；解析结果写回 [featureSnapshots]。
  Future<void> _resolveGradeFeatureSnapshot(
    _AcademicFeature feature,
    Map<_AcademicFeature, AcademicEamsHttpSnapshot> featureSnapshots,
    List<String> warnings,
  ) async {
    final resolved = await _resolveFeatureSnapshot(
      feature,
      featureSnapshots[feature],
      warnings,
    );
    if (resolved != null) {
      featureSnapshots[feature] = resolved;
    } else {
      featureSnapshots.remove(feature);
    }
  }

  /// 拉取指定学期的过程化成绩（平时成绩明细）。
  ///
  /// 过程化成绩为 EAMS 独立页面：成绩壳页提供学期日历，按学期 POST
  /// `person!processGrade.action` 获取该学期平时成绩表格。
  ///
  /// :param homeSnapshot: 已解析的 EAMS 首页快照，用于兜底来源地址。
  /// :param featureUris: 已发现的只读功能入口地址。
  /// :param warnings: 流程中累积的降级原因。
  /// :param campusNetworkStatus: 当前校园网状态，用于结果提示。
  /// :param targetTerm: 目标全局学期。
  /// :param targetSemester: 目标 EAMS 学期。
  /// :returns: 含过程化成绩快照的查询结果。
  Future<AcademicEamsQueryResult> _buildGradeProcessResult({
    required AcademicEamsHttpSnapshot homeSnapshot,
    required Map<_AcademicFeature, Uri> featureUris,
    required List<String> warnings,
    required CampusNetworkStatus? campusNetworkStatus,
    AcademicTermChoice? targetTerm,
    AcademicEamsSemesterOption? targetSemester,
  }) async {
    final shellUri = featureUris[_AcademicFeature.gradeCurrent];
    if (shellUri == null) {
      return _buildResult(
        AcademicEamsQueryStatus.readOnlyEntryUnavailable,
        message: '未识别到成绩查询入口',
        detail: warnings.isEmpty
            ? 'EAMS 只读菜单中没有可验证的成绩查询入口。'
            : warnings.join('；'),
        finalUri: homeSnapshot.finalUri,
        campusNetworkStatus: campusNetworkStatus,
      );
    }

    final shell = await _gateway.fetchPage(shellUri, timeout);
    if (_isAuthenticationRequired(shell) || _isUnavailable(shell)) {
      return _buildResult(
        AcademicEamsQueryStatus.systemUnavailable,
        message: '过程化成绩页面不可用',
        detail: '成绩页面返回登录页或不可用状态。',
        finalUri: shell.finalUri,
        campusNetworkStatus: campusNetworkStatus,
      );
    }

    final options = await _resolveExamSemesterOptions(shell, warnings);
    final selected = _selectExamSemester(
      options: options,
      fallbackSemesterId: _resolveAcademicSemesterId(shell.body),
      targetTerm: targetTerm,
      targetSemester: targetSemester,
    );

    final actionUri = shell.finalUri.resolve('person!processGrade.action');
    AcademicEamsHttpSnapshot dataSnapshot;
    try {
      dataSnapshot = await _gateway.submitForm(
        formUri: actionUri,
        method: 'POST',
        fields: {'projectType': 'MAJOR', 'semester.id': selected.id},
        timeout: timeout,
      );
    } on DioException {
      return _buildResult(
        AcademicEamsQueryStatus.networkError,
        message: '过程化成绩读取失败',
        detail: '提交过程化成绩查询时网络失败。',
        finalUri: actionUri,
        campusNetworkStatus: campusNetworkStatus,
      );
    } on TimeoutException {
      return _buildResult(
        AcademicEamsQueryStatus.networkError,
        message: '过程化成绩读取超时',
        detail: '提交过程化成绩查询超时。',
        finalUri: actionUri,
        campusNetworkStatus: campusNetworkStatus,
      );
    }

    final records = _parseGradeProcessRecords(dataSnapshot.body);
    final processSnapshot = AcademicGradeProcessSnapshot(
      records: records,
      selectedSemester: selected,
      semesterOptions: options,
      fetchedAt: DateTime.now(),
      sourceUri: dataSnapshot.finalUri,
    );
    final snapshot = AcademicEamsSnapshot(
      fetchedAt: processSnapshot.fetchedAt,
      sourceUri: processSnapshot.sourceUri,
      warnings: List.unmodifiable(warnings),
      hasCourseOfferingEntry: featureUris.containsKey(
        _AcademicFeature.courseOfferingsEntry,
      ),
      hasFreeClassroomEntry: featureUris.containsKey(
        _AcademicFeature.freeClassroomEntry,
      ),
      gradeProcess: processSnapshot,
    );
    return _buildResult(
      warnings.isEmpty
          ? AcademicEamsQueryStatus.success
          : AcademicEamsQueryStatus.partialSuccess,
      message: records.isEmpty ? '所选学期暂无过程化成绩' : '过程化成绩读取成功',
      detail: records.isEmpty ? '已读取所选学期，但未发现可展示的平时成绩。' : '已读取所选学期的平时成绩明细。',
      finalUri: processSnapshot.sourceUri,
      campusNetworkStatus: campusNetworkStatus,
      snapshot: snapshot,
    );
  }
}

/// 解析过程化成绩表格，仅保留含平时成绩的课程记录。
///
/// :param body: 过程化成绩页面 HTML 正文。
/// :returns: 过程化成绩记录列表。
List<AcademicGradeProcessRecord> _parseGradeProcessRecords(String body) {
  final document = html_parser.parse(body);
  for (final table in _parseTables(document)) {
    final headers = table.headers;
    final lowerHeaders = headers.map((header) => header.toLowerCase()).toList();
    if (!_containsAny(lowerHeaders, ['课程名称', '课程', 'course name']) ||
        !headers.any((header) => header.contains('平时成绩'))) {
      continue;
    }
    final processColumns = <int>[];
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].contains('平时成绩')) processColumns.add(i);
    }
    final records = <AcademicGradeProcessRecord>[];
    for (final row in table.rows) {
      final rowMap = _rowToMap(headers, row);
      final courseName = _pickValue(rowMap, ['课程名称', '课程', 'Course Name']);
      if (courseName == null || courseName.isEmpty) continue;
      final items = <AcademicGradeProcessItem>[];
      for (final column in processColumns) {
        if (column >= row.length) continue;
        final raw = row[column].replaceAll(RegExp(r'\s+'), '');
        if (raw.isEmpty || raw == '无' || raw == '-' || raw == '--') continue;
        final label = headers[column].split('/').first.trim();
        items.add(
          AcademicGradeProcessItem(
            label: label.isEmpty ? '平时成绩' : label,
            value: raw,
          ),
        );
      }
      if (items.isEmpty) continue;
      records.add(
        AcademicGradeProcessRecord(
          courseName: courseName,
          courseCode: _pickValue(rowMap, ['课程代码', '课程编号', 'Course Code']),
          courseSequence: _pickValue(rowMap, ['课程序号']),
          category: _pickValue(rowMap, ['课程类别', '类别', '课程性质']),
          termName: _pickValue(rowMap, ['学年学期', '学期']),
          credit: _parseDouble(_pickValue(rowMap, ['学分', 'Credit'])),
          items: items,
          rawCells: row,
        ),
      );
    }
    if (records.isNotEmpty) return List.unmodifiable(records);
  }
  return const <AcademicGradeProcessRecord>[];
}
