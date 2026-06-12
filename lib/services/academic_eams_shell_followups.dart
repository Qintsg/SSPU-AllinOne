/*
 * 本专科教务壳页跟随逻辑 — 从 EAMS 壳页继续读取真实课表、成绩和考试内容
 * @Project : SSPU-AllinOne
 * @File : academic_eams_shell_followups.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'academic_eams_service.dart';

extension _AcademicEamsShellFollowups on AcademicEamsService {
  Future<void> _resolveOptionalFeatureSnapshots(
    Map<_AcademicFeature, AcademicEamsHttpSnapshot> featureSnapshots,
    List<String> warnings,
  ) async {
    for (final feature in [
      _AcademicFeature.gradeCurrent,
      _AcademicFeature.gradeHistory,
      _AcademicFeature.exams,
      _AcademicFeature.programPlan,
    ]) {
      final resolvedSnapshot = await _resolveFeatureSnapshot(
        feature,
        featureSnapshots[feature],
        warnings,
      );
      if (resolvedSnapshot != null) {
        featureSnapshots[feature] = resolvedSnapshot;
      } else {
        featureSnapshots.remove(feature);
      }
    }
  }

  Future<AcademicEamsHttpSnapshot?> _resolveFeatureSnapshot(
    _AcademicFeature feature,
    AcademicEamsHttpSnapshot? snapshot,
    List<String> warnings,
  ) async {
    if (snapshot == null) return null;
    return switch (feature) {
      _AcademicFeature.courseTable => _resolveCourseTableSnapshot(
        snapshot,
        warnings,
      ),
      _AcademicFeature.gradeCurrent => _resolveCurrentGradeSnapshot(
        snapshot,
        warnings,
      ),
      _AcademicFeature.exams => _resolveExamSnapshot(snapshot, warnings),
      _AcademicFeature.programPlan => _resolveProgramPlanSnapshot(
        snapshot,
        warnings,
      ),
      _ => snapshot,
    };
  }

  Future<AcademicEamsHttpSnapshot> _resolveCourseTableSnapshot(
    AcademicEamsHttpSnapshot shellSnapshot,
    List<String> warnings,
  ) async {
    final actionUri = _extractRelativeActionUri(shellSnapshot, const [
      'courseTableForStd!courseTable.action',
    ]);
    if (actionUri == null) return shellSnapshot;

    final form = _parseShellForm(shellSnapshot, '#courseTableForm');
    if (form == null) {
      warnings.add('课表壳页缺少可提交表单，已保留入口页结果');
      return shellSnapshot;
    }

    final fields = Map<String, String>.from(form.defaultFields);
    final kind = (fields['setting.kind'] ?? '').trim().isEmpty
        ? 'std'
        : (fields['setting.kind'] ?? '');
    fields['setting.kind'] = kind;
    final idsValue = _extractRegexValue(
      shellSnapshot.body,
      RegExp(
        kind == 'std'
            ? r'bg\.form\.addInput\(form,"ids","([^"]+)"\)'
            : r'bg\.form\.addInput\(form,"ids","([^"]+)"\)',
      ),
    );
    if (idsValue != null && idsValue.isNotEmpty) fields['ids'] = idsValue;
    fields['startWeek'] = (fields['startWeek'] ?? '').trim().isEmpty
        ? '1'
        : (fields['startWeek'] ?? '');
    fields['semester.id'] = _resolveAcademicSemesterId(shellSnapshot.body);

    final resultSnapshot = await _gateway.submitForm(
      formUri: actionUri,
      method: form.method,
      fields: fields,
      timeout: timeout,
    );
    return resultSnapshot;
  }

  Future<AcademicEamsHttpSnapshot> _resolveCurrentGradeSnapshot(
    AcademicEamsHttpSnapshot shellSnapshot,
    List<String> warnings,
  ) async {
    final searchUri = _extractRelativeActionUri(shellSnapshot, const [
      '/eams/teach/grade/course/person!search.action',
    ]);
    if (searchUri == null) return shellSnapshot;

    try {
      return await _gateway.fetchPage(searchUri, timeout);
    } on DioException {
      warnings.add('当前成绩壳页的查询 action 读取失败，已保留入口页结果');
      return shellSnapshot;
    } on TimeoutException {
      warnings.add('当前成绩壳页的查询 action 读取超时，已保留入口页结果');
      return shellSnapshot;
    }
  }

  Future<AcademicEamsHttpSnapshot?> _resolveExamSnapshot(
    AcademicEamsHttpSnapshot? shellSnapshot,
    List<String> warnings, {
    AcademicTermChoice? targetTerm,
    AcademicEamsSemesterOption? targetSemester,
    String? examTypeId,
  }) async {
    if (shellSnapshot == null) return null;
    final actionUri = _extractRelativeActionUri(shellSnapshot, const [
      'stdExamTable!examTable.action',
    ]);
    if (actionUri == null) return shellSnapshot;

    final semesterOptions = await _resolveExamSemesterOptions(
      shellSnapshot,
      warnings,
    );
    final defaultSemester = _selectExamSemester(
      options: semesterOptions,
      fallbackSemesterId: _resolveAcademicSemesterId(shellSnapshot.body),
      targetTerm: targetTerm,
      targetSemester: targetSemester,
    );
    final examTypes = _extractExamTypeOptions(shellSnapshot.body);
    final typeOptions = examTypes.isEmpty ? const {'1': '期末考试'} : examTypes;
    // 默认仅查询期末考试；按需切换其它类型，避免一次请求 5 类产生大量未发布占位行。
    final selectedType = _selectExamType(typeOptions, examTypeId);

    const emptyBody =
        '<html><body><table><tr><th>考试类型</th><th>课程序号</th>'
        '<th>课程名称</th><th>考试日期</th><th>考试安排</th><th>考试地点</th>'
        '<th>考试情况</th><th>其它说明</th></tr></table></body></html>';
    final metadata = <String, Object?>{
      'selectedSemester': defaultSemester.toJson(),
      'semesterOptions': [
        for (final option in semesterOptions) option.toJson(),
      ],
      'examTypeOptions': typeOptions,
      'selectedExamType': selectedType,
    };

    try {
      final queryUri = actionUri.replace(
        queryParameters: {
          ...actionUri.queryParameters,
          'semester.id': defaultSemester.id,
          'examType.id': selectedType,
        },
      );
      final snapshot = await _gateway.fetchPage(queryUri, timeout);
      final isDegraded =
          _isAuthenticationRequired(snapshot) || _isUnavailable(snapshot);
      if (isDegraded) {
        warnings.add('考试安排子表读取降级，已返回所选学期空安排');
      }
      final body = isDegraded
          ? emptyBody
          : '<html><body>'
                '${_injectExamTypeColumn(snapshot.body, typeOptions[selectedType] ?? selectedType)}'
                '</body></html>';
      return AcademicEamsHttpSnapshot(
        finalUri: queryUri,
        statusCode: 200,
        body: body,
        metadata: metadata,
      );
    } on DioException {
      warnings.add('考试壳页的 examTable action 读取失败，已保留入口页结果');
      return shellSnapshot;
    } on TimeoutException {
      warnings.add('考试壳页的 examTable action 读取超时，已保留入口页结果');
      return shellSnapshot;
    }
  }

  /// 选定要查询的考试类型，默认期末考试（examType.id=1）。
  String _selectExamType(Map<String, String> typeOptions, String? requested) {
    if (requested != null && typeOptions.containsKey(requested)) {
      return requested;
    }
    if (typeOptions.containsKey('1')) return '1';
    return typeOptions.keys.first;
  }

  Future<AcademicEamsHttpSnapshot?> _resolveProgramPlanSnapshot(
    AcademicEamsHttpSnapshot shellSnapshot,
    List<String> warnings,
  ) async {
    if (_isUnavailable(shellSnapshot)) {
      warnings.add('培养计划页面当前无访问权限');
      return null;
    }
    return shellSnapshot;
  }

  _AcademicReadonlyQueryForm? _parseShellForm(
    AcademicEamsHttpSnapshot snapshot,
    String selector,
  ) {
    final document = html_parser.parse(snapshot.body);
    final form = document.querySelector(selector);
    if (form == null) return null;

    final defaults = <String, String>{};
    for (final input in form.querySelectorAll('input')) {
      final name = input.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;
      defaults[name] = input.attributes['value'] ?? '';
    }
    for (final select in form.querySelectorAll('select')) {
      final name = select.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;
      defaults[name] = _resolveSelectDefaultValue(select);
    }

    final action = form.attributes['action']?.trim() ?? snapshot.finalUri.path;
    final method = form.attributes['method']?.trim().toUpperCase() ?? 'POST';
    return _AcademicReadonlyQueryForm(
      actionUri: snapshot.finalUri.resolve(action),
      method: method,
      defaultFields: Map.unmodifiable(defaults),
      fieldNamesByIntent: const {},
    );
  }

  Uri? _extractRelativeActionUri(
    AcademicEamsHttpSnapshot snapshot,
    List<String> candidates,
  ) {
    for (final candidate in candidates) {
      final escapedCandidate = RegExp.escape(candidate);
      final patterns = [
        RegExp("['\"]($escapedCandidate(?:\\?[^'\"]*)?)['\"]"),
        RegExp('$escapedCandidate(?:\\?[^"\\\'\\s<>]*)?'),
      ];
      for (final pattern in patterns) {
        final match = pattern.firstMatch(snapshot.body);
        final value = match?.group(1) ?? match?.group(0);
        final normalizedValue = value?.trim();
        if (normalizedValue == null || normalizedValue.isEmpty) continue;
        return snapshot.finalUri.resolve(normalizedValue);
      }
    }
    return null;
  }

  String _resolveAcademicSemesterId(String body) {
    final document = html_parser.parse(body);
    for (final element in document.querySelectorAll(
      'input[name="semester.id"], select[name="semester.id"]',
    )) {
      final value = element.localName == 'select'
          ? _resolveSelectDefaultValue(element)
          : element.attributes['value']?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final value =
        _extractRegexValue(body, RegExp(r'value:"(\d+)"')) ??
        _extractRegexValue(body, RegExp(r"value:'(\d+)'")) ??
        _extractRegexValue(body, RegExp(r'value\s*:\s*"(\d+)"')) ??
        _extractRegexValue(body, RegExp(r"value\s*:\s*'(\d+)'")) ??
        _extractRegexValue(body, RegExp(r'semesterId=(\d+)')) ??
        _extractRegexValue(
          body,
          RegExp(
            r'name=["'
            "'"
            r']semester\.id["'
            "'"
            r'][^>]*value=["'
            "'"
            r'](\d+)["'
            "'"
            r']',
            caseSensitive: false,
          ),
        );
    return value ?? '';
  }

  Map<String, String> _extractExamTypeOptions(String body) {
    final document = html_parser.parse(body);
    final options = <String, String>{};
    for (final select in document.querySelectorAll('select')) {
      final name = (select.attributes['name'] ?? '').toLowerCase();
      final id = (select.attributes['id'] ?? '').toLowerCase();
      if (!name.contains('examtype') && !id.contains('examtype')) continue;
      for (final option in select.querySelectorAll('option')) {
        final value = option.attributes['value']?.trim() ?? '';
        final text = _cleanText(option.text);
        if (value.isNotEmpty) options[value] = text.isEmpty ? value : text;
      }
    }
    if (options.isNotEmpty) return options;

    final pattern = RegExp(
      r'<option\s+value="(\d+)"[^>]*>([^<]+)</option>',
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(body)) {
      final value = match.group(1)?.trim() ?? '';
      final text = _cleanText(match.group(2) ?? '');
      if (value.isNotEmpty && text.contains('考试')) {
        options[value] = text;
      }
    }
    return options;
  }

  Future<List<AcademicEamsSemesterOption>> _resolveExamSemesterOptions(
    AcademicEamsHttpSnapshot shellSnapshot,
    List<String> warnings,
  ) async {
    final tagId = _extractSemesterTagId(shellSnapshot.body);
    final defaultSemesterId = _resolveAcademicSemesterId(shellSnapshot.body);
    if (tagId == null || tagId.isEmpty) {
      final option = _extractSemesterOptionFromShell(shellSnapshot.body);
      return option == null ? const [] : [option];
    }

    try {
      final dataQueryUri = shellSnapshot.finalUri.resolve('dataQuery.action');
      final dataQuerySnapshot = await _gateway.submitForm(
        formUri: dataQueryUri,
        method: 'POST',
        fields: {
          'tagId': tagId,
          'dataType': 'semesterCalendar',
          'empty': 'false',
          'value': defaultSemesterId,
        },
        timeout: timeout,
      );
      final parsedOptions = _parseSemesterCalendarOptions(
        dataQuerySnapshot.body,
      );
      if (parsedOptions.isNotEmpty) return parsedOptions;
    } on DioException {
      warnings.add('考试学期列表读取失败，已使用页面默认学期继续查询');
    } on TimeoutException {
      warnings.add('考试学期列表读取超时，已使用页面默认学期继续查询');
    }
    final option = _extractSemesterOptionFromShell(shellSnapshot.body);
    return option == null ? const [] : [option];
  }

  AcademicEamsSemesterOption _selectExamSemester({
    required List<AcademicEamsSemesterOption> options,
    required String fallbackSemesterId,
    AcademicTermChoice? targetTerm,
    AcademicEamsSemesterOption? targetSemester,
  }) {
    if (targetTerm != null) {
      for (final option in options) {
        if (option.matchesTerm(targetTerm)) return option;
      }
    }
    if (targetSemester != null &&
        targetSemester.id.trim().isNotEmpty &&
        (targetTerm == null || targetSemester.matchesTerm(targetTerm))) {
      return targetSemester;
    }
    if (targetTerm != null) {
      final inferred = _inferExamSemesterFromOptions(options, targetTerm);
      if (inferred != null) return inferred;
    }
    for (final option in options) {
      if (option.id == fallbackSemesterId) return option;
    }
    if (options.isNotEmpty) return options.last;
    return AcademicEamsSemesterOption(
      id: fallbackSemesterId,
      label: fallbackSemesterId,
    );
  }

  AcademicEamsSemesterOption? _inferExamSemesterFromOptions(
    List<AcademicEamsSemesterOption> options,
    AcademicTermChoice targetTerm,
  ) {
    final targetTermCode = _termCodeForSeason(targetTerm.season);
    if (targetTermCode == null) return null;

    for (final option in options) {
      final optionYear = option.academicYear;
      final optionTermCode = _eamsTermCodeAsNumber(option.termCode);
      final optionId = int.tryParse(option.id);
      if (optionYear == null || optionTermCode == null || optionId == null) {
        continue;
      }
      final yearDelta = targetTerm.academicYear - optionYear;
      final termDelta = targetTermCode - optionTermCode;
      final inferredId = optionId + yearDelta * 3 + termDelta;
      if (inferredId <= 0) continue;
      return AcademicEamsSemesterOption.fromEamsFields(
        id: inferredId.toString(),
        schoolYear: '${targetTerm.academicYear}-${targetTerm.academicYear + 1}',
        termCode: targetTermCode.toString(),
      );
    }
    return null;
  }

  int? _eamsTermCodeAsNumber(String? code) {
    return switch (code?.replaceAll(RegExp(r'\s+'), '')) {
      '1' || '一' || '第1学期' || '第一学期' || '秋' || '秋季' || '秋季学期' => 1,
      '2' || '二' || '第2学期' || '第二学期' || '春' || '春季' || '春季学期' => 2,
      '3' || '三' || '第3学期' || '第三学期' || '夏' || '夏季' || '夏季学期' => 3,
      _ => null,
    };
  }

  int? _termCodeForSeason(AcademicTermSeason season) {
    return switch (season) {
      AcademicTermSeason.fall => 1,
      AcademicTermSeason.spring => 2,
      AcademicTermSeason.summer => 3,
    };
  }

  String? _extractSemesterTagId(String body) {
    return _extractRegexValue(body, RegExp(r'tagId\s*:\s*"([^"]+)"')) ??
        _extractRegexValue(body, RegExp(r"tagId\s*:\s*'([^']+)'")) ??
        _extractRegexValue(body, RegExp(r'id\s*:\s*"([^"]*semester[^"]*)"')) ??
        _extractRegexValue(body, RegExp(r"id\s*:\s*'([^']*semester[^']*)'")) ??
        _extractRegexValue(
          body,
          RegExp(r'id="([^"]+semester[^"]*)"', caseSensitive: false),
        );
  }

  AcademicEamsSemesterOption? _extractSemesterOptionFromShell(String body) {
    final document = html_parser.parse(body);
    for (final select in document.querySelectorAll('select')) {
      final name = (select.attributes['name'] ?? '').toLowerCase();
      final id = (select.attributes['id'] ?? '').toLowerCase();
      if (!name.contains('semester') && !id.contains('semester')) continue;
      for (final option in select.querySelectorAll('option')) {
        final value = option.attributes['value']?.trim() ?? '';
        final text = _cleanText(option.text);
        if (value.isEmpty || text.isEmpty) continue;
        final parsed = _parseSemesterOption(value: value, label: text);
        if (parsed != null) return parsed;
      }
    }
    for (final option in document.querySelectorAll('option')) {
      final value = option.attributes['value']?.trim() ?? '';
      final text = _cleanText(option.text);
      if (value.isEmpty || !RegExp(r'\d{4}\s*-\s*\d{4}').hasMatch(text)) {
        continue;
      }
      final parsed = _parseSemesterOption(value: value, label: text);
      if (parsed != null) return parsed;
    }
    final fallbackId = _resolveAcademicSemesterId(body);
    if (fallbackId.isEmpty) return null;
    return AcademicEamsSemesterOption(id: fallbackId, label: fallbackId);
  }

  List<AcademicEamsSemesterOption> _parseSemesterCalendarOptions(String body) {
    final result = <AcademicEamsSemesterOption>[];
    final objectPattern = RegExp(r'\{[^{}]*(?:schoolYear|name)[^{}]*\}');
    for (final object in objectPattern.allMatches(body)) {
      final text = object.group(0) ?? '';
      final id =
          _extractRegexValue(text, RegExp(r'id\s*:\s*(\d+)')) ??
          _extractRegexValue(text, RegExp(r'"id"\s*:\s*"?(\d+)"?'));
      final schoolYear =
          _extractRegexValue(text, RegExp(r'schoolYear\s*:\s*"([^"]+)"')) ??
          _extractRegexValue(text, RegExp(r"schoolYear\s*:\s*'([^']+)'")) ??
          _extractRegexValue(text, RegExp(r'"schoolYear"\s*:\s*"([^"]+)"'));
      final termCode =
          _extractRegexValue(text, RegExp(r'name\s*:\s*"([^"]+)"')) ??
          _extractRegexValue(text, RegExp(r"name\s*:\s*'([^']+)'")) ??
          _extractRegexValue(text, RegExp(r'"name"\s*:\s*"([^"]+)"'));
      if (id == null ||
          schoolYear == null ||
          termCode == null ||
          id.isEmpty ||
          schoolYear.isEmpty ||
          termCode.isEmpty) {
        continue;
      }
      result.add(
        AcademicEamsSemesterOption.fromEamsFields(
          id: id,
          schoolYear: schoolYear,
          termCode: termCode,
        ),
      );
    }
    if (result.isNotEmpty) return List.unmodifiable(_dedupeSemesters(result));

    final optionPattern = RegExp(
      r'<option[^>]*value=["'
      "'"
      r']?(\d+)["'
      "'"
      r']?[^>]*>([^<]+)</option>',
      caseSensitive: false,
    );
    for (final match in optionPattern.allMatches(body)) {
      final id = match.group(1) ?? '';
      final label = _cleanText(match.group(2) ?? '');
      final option = _parseSemesterOption(value: id, label: label);
      if (option != null) result.add(option);
    }
    return List.unmodifiable(_dedupeSemesters(result));
  }

  List<AcademicEamsSemesterOption> _dedupeSemesters(
    List<AcademicEamsSemesterOption> options,
  ) {
    final seen = <String>{};
    final result = <AcademicEamsSemesterOption>[];
    for (final option in options) {
      if (option.id.trim().isEmpty || !seen.add(option.id)) continue;
      result.add(option);
    }
    result.sort((a, b) {
      final yearCompare = (a.academicYear ?? 0).compareTo(b.academicYear ?? 0);
      if (yearCompare != 0) return yearCompare;
      return (a.termCode ?? '').compareTo(b.termCode ?? '');
    });
    return result;
  }

  AcademicEamsSemesterOption? _parseSemesterOption({
    required String value,
    required String label,
  }) {
    final match = RegExp(
      r'(\d{4})\s*-\s*(\d{4})\s*-?\s*(1|2|3|秋季?|春季?|夏季?)',
    ).firstMatch(label);
    if (match == null) {
      return AcademicEamsSemesterOption(id: value, label: label);
    }
    return AcademicEamsSemesterOption.fromEamsFields(
      id: value,
      schoolYear: '${match.group(1)}-${match.group(2)}',
      termCode: match.group(3) ?? '',
    );
  }

  String _injectExamTypeColumn(String body, String examType) {
    final document = html_parser.parse(body);
    for (final table in document.querySelectorAll('table')) {
      final rows = table.querySelectorAll('tr');
      if (rows.isEmpty) continue;
      final headerCells = rows.first.querySelectorAll('th,td');
      final headerTexts = headerCells.map((cell) => _cleanText(cell.text));
      if (headerTexts.any((text) => text.contains('考试类型'))) continue;
      final header = html_dom.Element.tag('th')..text = '考试类型';
      rows.first.nodes.insert(0, header);
      for (final row in rows.skip(1)) {
        final cell = html_dom.Element.tag('td')..text = examType;
        row.nodes.insert(0, cell);
      }
    }
    return document.body?.innerHtml ?? body;
  }

  String? _extractRegexValue(String body, RegExp pattern) {
    final match = pattern.firstMatch(body);
    return match?.groupCount == 0 ? match?.group(0) : match?.group(1);
  }
}
