/*
 * 空闲教室查询页测试 — 校验只读条件提交、结果与移动端布局
 * @Project : SSPU-AllinOne
 * @File : academic_free_classroom_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';

void main() {
  testWidgets('空闲教室页提交当日节次并展示只读结果', (tester) async {
    final client = _FakeFreeClassroomClient();
    await tester.pumpWidget(
      YhApp(
        home: AcademicFreeClassroomPage(
          client: client,
          nowOverride: DateTime(2026, 9, 8),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('free-classroom-search')));
    await tester.pumpAndSettle();

    expect(client.lastCriteria?.dateText, '2026-09-08');
    expect(client.lastCriteria?.lessonFrom, 1);
    expect(client.lastCriteria?.lessonTo, 2);
    expect(find.text('综合楼 A301'), findsOneWidget);
    expect(find.text('120 座'), findsOneWidget);
    expect(find.textContaining('只读'), findsWidgets);
    expect(find.textContaining('预约'), findsNothing);
  });

  testWidgets('空闲教室页在移动宽度下无溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: AcademicFreeClassroomPage(
          client: _FakeFreeClassroomClient(),
          nowOverride: DateTime(2026, 9, 8),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('free-classroom-search')));
    await tester.pumpAndSettle();

    expect(find.text('空闲教室'), findsWidgets);
    expect(find.text('综合楼 A301'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空闲教室页展示空结果、登录失效和网络失败状态', (tester) async {
    final statuses = [
      (AcademicEamsQueryStatus.success, '当前条件没有可用教室', '调整后重试'),
      (AcademicEamsQueryStatus.oaLoginRequired, '请重新登录教务系统', '重新查询'),
      (AcademicEamsQueryStatus.networkError, '空闲教室网络失败', '重新查询'),
    ];
    for (final (status, message, action) in statuses) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final client = _FakeFreeClassroomClient(
        responses: [
          _freeClassroomResult(
            AcademicFreeClassroomSearchCriteria(
              dateText: '2026-09-08',
              lessonFrom: 1,
              lessonTo: 2,
            ),
            status: status,
            records: const [],
            message: message,
          ),
        ],
      );
      await tester.pumpWidget(
        YhApp(
          home: AcademicFreeClassroomPage(
            client: client,
            nowOverride: DateTime(2026, 9, 8),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('free-classroom-search')));
      await tester.pumpAndSettle();
      expect(find.textContaining(message), findsOneWidget);
      expect(find.bySemanticsLabel(action), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('空闲教室查询失败时保留上一次有效列表', (tester) async {
    final criteria = const AcademicFreeClassroomSearchCriteria(
      dateText: '2026-09-08',
      lessonFrom: 1,
      lessonTo: 2,
    );
    final client = _FakeFreeClassroomClient(
      responses: [
        _freeClassroomResult(
          criteria,
          records: const [
            AcademicFreeClassroomRecord(
              roomName: '综合楼 A301',
              campus: '金海路校区',
              building: '综合楼',
              capacity: 120,
              lessonText: '1-2',
              rawCells: ['综合楼 A301'],
            ),
          ],
        ),
        _freeClassroomResult(
          criteria,
          status: AcademicEamsQueryStatus.networkError,
          records: const [],
          message: '空闲教室网络失败',
        ),
      ],
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicFreeClassroomPage(
          client: client,
          nowOverride: DateTime(2026, 9, 8),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('free-classroom-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('free-classroom-search')));
    await tester.pumpAndSettle();

    expect(find.textContaining('空闲教室网络失败'), findsOneWidget);
    expect(find.textContaining('已保留上一次有效结果。'), findsOneWidget);
    expect(find.text('综合楼 A301'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeFreeClassroomClient implements AcademicFreeClassroomClient {
  _FakeFreeClassroomClient({this.responses = const []});

  final List<AcademicEamsQueryResult> responses;
  AcademicFreeClassroomSearchCriteria? lastCriteria;

  @override
  Future<AcademicEamsQueryResult> searchFreeClassrooms(
    AcademicFreeClassroomSearchCriteria criteria,
  ) async {
    lastCriteria = criteria;
    if (responses.isNotEmpty) return responses.removeAt(0);
    final now = DateTime(2026, 9, 8, 9);
    return _freeClassroomResult(
      criteria,
      checkedAt: now,
      records: const [
        AcademicFreeClassroomRecord(
          roomName: '综合楼 A301',
          campus: '金海路校区',
          building: '综合楼',
          capacity: 120,
          dateText: '2026-09-08',
          lessonText: '1-2',
          rawCells: ['综合楼 A301', '金海路校区', '120'],
        ),
      ],
    );
  }
}

AcademicEamsQueryResult _freeClassroomResult(
  AcademicFreeClassroomSearchCriteria criteria, {
  AcademicEamsQueryStatus status = AcademicEamsQueryStatus.success,
  List<AcademicFreeClassroomRecord> records = const [],
  String message = '空闲教室查询成功',
  DateTime? checkedAt,
}) {
  final now = checkedAt ?? DateTime(2026, 9, 8, 9);
  return AcademicEamsQueryResult(
    status: status,
    message: message,
    detail: status == AcademicEamsQueryStatus.success
        ? '已读取空闲教室列表。'
        : '请检查网络或登录状态后重试。',
    checkedAt: now,
    entranceUri: Uri.parse('https://oa.sspu.edu.cn/'),
    finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/classroom.action'),
    freeClassrooms: AcademicFreeClassroomSearchResult(
      criteria: criteria,
      records: records,
      fetchedAt: now,
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/classroom.action'),
    ),
  );
}
