/* 校历 PDF 清源工具栏契约测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/academic_calendar_pdf_page.dart';

void main() {
  testWidgets('PDF 框架始终提供页码缩放下载与外部打开', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPdfFrame(
          title: '校历',
          document: const SizedBox.expand(),
          pageLabel: '第 1 / 4 页',
          onBack: () {},
          onZoomOut: () {},
          onZoomIn: () {},
          onDownload: () {},
          onOpenExternal: () {},
        ),
      ),
    );

    expect(find.text('第 1 / 4 页'), findsOneWidget);
    expect(find.bySemanticsLabel('缩小 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('放大 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('下载校历 PDF'), findsOneWidget);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);
  });
}
