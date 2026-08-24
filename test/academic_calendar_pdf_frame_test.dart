/* 校历 PDF 清源工具栏契约测试。 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/academic_calendar_pdf_frame.dart';
import 'package:sspu_allinone/pages/academic_calendar_pdf_page.dart';

void main() {
  testWidgets('PDF 框架始终提供页码缩放下载与外部打开', (tester) async {
    var downloadCount = 0;
    var openExternalCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfFrame(
          title: '校历',
          document: const SizedBox.expand(),
          pageLabel: '第 1 / 4 页',
          onBack: () {},
          onZoomOut: () {},
          onZoomIn: () {},
          onDownload: () => downloadCount += 1,
          onOpenExternal: () => openExternalCount += 1,
        ),
      ),
    );

    expect(find.text('第 1 / 4 页'), findsOneWidget);
    expect(find.bySemanticsLabel('缩小 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('放大 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('下载校历 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    expect(downloadCount, 1);
    expect(openExternalCount, 1);
  });

  testWidgets('PDF 下载共享单飞锁且来源换代后旧结果不得反馈', (tester) async {
    final oldDownload = Completer<void>();
    var downloadCount = 0;
    Widget page(String source) => AcademicCalendarPdfPage(
      title: '校历',
      pdfUrl: source,
      documentBuilder: (context, current, revision, actions) =>
          Center(child: Text('正文：$current')),
      downloadOverride: (current, title) {
        downloadCount++;
        return oldDownload.future;
      },
    );

    await tester.pumpWidget(YhApp(home: page('https://a.invalid/old.pdf')));
    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    await tester.pump();
    expect(find.textContaining('正在下载校历 PDF'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('下载校历 PDF'), warnIfMissed: false);
    await tester.pump();
    expect(downloadCount, 1);

    await tester.pumpWidget(YhApp(home: page('https://b.invalid/new.pdf')));
    await tester.pump();
    expect(find.text('正文：https://b.invalid/new.pdf'), findsOneWidget);
    oldDownload.complete();
    await tester.pumpAndSettle();

    expect(find.text('校历 PDF 已保存到下载目录'), findsNothing);
    expect(find.text('正文：https://b.invalid/new.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF 外部打开确认失败后保留正文并可原位重试', (tester) async {
    var launchCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfPage(
          title: '2025-2026 学年校历',
          pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
          documentBuilder: (context, source, revision, actions) =>
              const Center(child: Text('固定 PDF 正文')),
          launchExternalOverride: (uri) async {
            launchCount++;
            return false;
          },
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    expect(find.text('在外部应用打开校历？'), findsOneWidget);
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(launchCount, 1);
    expect(find.textContaining('系统未能打开校历 PDF'), findsOneWidget);
    expect(find.text('固定 PDF 正文'), findsOneWidget);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF 外部打开取消后不启动外部应用并保留正文', (tester) async {
    var launchCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfPage(
          title: '2025-2026 学年校历',
          pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
          initialPageCount: 4,
          documentBuilder: (context, source, revision, actions) =>
              const Center(child: Text('固定 PDF 正文')),
          launchExternalOverride: (uri) async {
            launchCount++;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(launchCount, 0);
    expect(find.text('固定 PDF 正文'), findsOneWidget);
    expect(find.text('第 1 / 4 页'), findsOneWidget);
    expect(find.textContaining('系统未能打开校历 PDF'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF 下载异常后解除共享锁并保留正文供原位重试', (tester) async {
    var downloadCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfPage(
          title: '校历',
          pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
          initialPageCount: 4,
          documentBuilder: (context, source, revision, actions) =>
              const Center(child: Text('固定 PDF 正文')),
          downloadOverride: (source, title) async {
            downloadCount++;
            throw StateError('download failed');
          },
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('校历 PDF 未能保存到下载目录'), findsWidgets);
    expect(find.text('固定 PDF 正文'), findsOneWidget);
    expect(find.text('第 1 / 4 页'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    await tester.pumpAndSettle();
    expect(downloadCount, 2);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF 下载期间正文重试不能绕过锁且完成后保留页码', (tester) async {
    final download = Completer<void>();
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfPage(
          title: '校历',
          pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
          initialPageNumber: 3,
          initialPageCount: 4,
          documentBuilder: (context, source, revision, actions) => Column(
            children: [
              Text('正文代次：$revision'),
              YhButton(label: '重试正文', onTap: actions.retry),
            ],
          ),
          downloadOverride: (source, title) => download.future,
        ),
      ),
    );

    expect(find.text('正文代次：0'), findsOneWidget);
    expect(find.text('第 3 / 4 页'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    await tester.pump();
    await tester.tap(find.text('重试正文'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('正文代次：0'), findsOneWidget);

    download.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试正文'));
    await tester.pump();
    expect(find.text('正文代次：1'), findsOneWidget);
    expect(find.text('第 3 / 4 页'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF 外部打开来源换代后旧结果不得污染新正文', (tester) async {
    final oldLaunch = Completer<bool>();
    Widget page(String source) => AcademicCalendarPdfPage(
      title: '校历',
      pdfUrl: source,
      initialPageCount: 4,
      documentBuilder: (context, current, revision, actions) =>
          Center(child: Text('正文：$current')),
      launchExternalOverride: (uri) => oldLaunch.future,
    );

    await tester.pumpWidget(YhApp(home: page('https://a.invalid/old.pdf')));
    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();
    await tester.pumpWidget(YhApp(home: page('https://b.invalid/new.pdf')));
    await tester.pump();
    oldLaunch.complete(false);
    await tester.pumpAndSettle();

    expect(find.text('正文：https://b.invalid/new.pdf'), findsOneWidget);
    expect(find.textContaining('系统未能打开校历 PDF'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
