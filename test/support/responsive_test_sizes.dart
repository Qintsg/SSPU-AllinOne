import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

const compactTestViewport = Size(360, 800);
const mediumTestViewport = Size(768, 900);
const expandedTestViewport = Size(1200, 900);
const courseOverflowRegressionViewport = Size(1084, 706);

Future<void> setResponsiveTestViewport(
  WidgetTester tester,
  Size viewport,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  await tester.binding.setSurfaceSize(viewport);
}

Future<void> resetResponsiveTestViewport(WidgetTester tester) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.binding.setSurfaceSize(null);
}
