/* 清源视觉回归比较器测试。 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../tool/visual_compare.dart';

void main() {
  test('完全一致截图以 1.0 通过应用阈值', () {
    final baseline = _solidImage(32, 32, red: 34, green: 80, blue: 110);
    final result = compareVisuals(
      baseline: baseline,
      actual: image.Image.from(baseline),
      applicationThreshold: 0.95,
      externalThreshold: 0.95,
    );

    expect(result.applicationSsim, 1.0);
    expect(result.passed, isTrue);
  });

  test('应用自绘区域低于 0.95 时单图失败', () {
    final baseline = _solidImage(32, 32, red: 255, green: 255, blue: 255);
    final actual = image.Image.from(baseline);
    for (var y = 0; y < 16; y += 1) {
      for (var x = 0; x < 16; x += 1) {
        actual.setPixelRgb(x, y, 0, 0, 0);
      }
    }

    final result = compareVisuals(
      baseline: baseline,
      actual: actual,
      applicationThreshold: 0.95,
      externalThreshold: 0.95,
    );

    expect(result.applicationSsim, lessThan(0.95));
    expect(result.passed, isFalse);
    expect(result.heatmap.getPixel(0, 0).r, 255);
  });

  test('抗锯齿归一化不会隐藏明显布局位移', () {
    final baseline = _solidImage(64, 64, red: 255, green: 255, blue: 255);
    final actual = image.Image.from(baseline);
    for (var y = 16; y < 48; y += 1) {
      for (var x = 8; x < 24; x += 1) {
        baseline.setPixelRgb(x, y, 0, 0, 0);
      }
      for (var x = 16; x < 32; x += 1) {
        actual.setPixelRgb(x, y, 0, 0, 0);
      }
    }

    final result = compareVisuals(
      baseline: baseline,
      actual: actual,
      applicationThreshold: 0.95,
      externalThreshold: 0.95,
    );

    expect(result.applicationSsim, lessThan(0.95));
    expect(result.passed, isFalse);
  });

  test('外部区域按 0.95 独立判定且不拖低应用区域', () {
    final baseline = _solidImage(32, 32, red: 240, green: 240, blue: 240);
    final actual = image.Image.from(baseline);
    for (var y = 8; y < 24; y += 1) {
      for (var x = 8; x < 24; x += 1) {
        actual.setPixelRgb(x, y, 225, 225, 225);
      }
    }
    const region = VisualRegion(
      id: 'document',
      x: 8,
      y: 8,
      width: 16,
      height: 16,
    );

    final result = compareVisuals(
      baseline: baseline,
      actual: actual,
      applicationThreshold: 0.95,
      externalThreshold: 0.95,
      externalRegions: const [region],
    );

    expect(result.applicationSsim, 1.0);
    expect(result.externalRegions, hasLength(1));
    expect(result.externalRegions.single.threshold, 0.95);
    expect(result.externalRegions.single.passed, isTrue);
    expect(result.passed, isTrue);
  });

  test('尺寸不一致直接拒绝比较', () {
    expect(
      () => compareVisuals(
        baseline: _solidImage(32, 32, red: 0, green: 0, blue: 0),
        actual: _solidImage(16, 16, red: 0, green: 0, blue: 0),
        applicationThreshold: 0.95,
        externalThreshold: 0.95,
      ),
      throwsArgumentError,
    );
  });

  test('命令行失败报告包含实际图、基准图和差异热图', () async {
    final root = await Directory.systemTemp.createTemp('visual-compare-');
    addTearDown(() => root.delete(recursive: true));
    final baseline = Directory('${root.path}/baseline')..createSync();
    final actual = Directory('${root.path}/actual')..createSync();
    final output = Directory('${root.path}/output');
    final manifest = File('${root.path}/manifest.json');
    await manifest.writeAsString(
      jsonEncode({
        'meta': {
          'applicationThreshold': 0.95,
          'externalThreshold': 0.95,
          'platforms': ['windows'],
        },
      }),
    );
    await File('${baseline.path}/shell.png').writeAsBytes(
      image.encodePng(_solidImage(16, 16, red: 255, green: 255, blue: 255)),
    );
    await File('${actual.path}/shell.png').writeAsBytes(
      image.encodePng(_solidImage(16, 16, red: 0, green: 0, blue: 0)),
    );

    final exitCode = await runVisualComparison([
      '--baseline',
      baseline.path,
      '--actual',
      actual.path,
      '--output',
      output.path,
      '--manifest',
      manifest.path,
      '--platform',
      'windows',
    ]);

    expect(exitCode, 1);
    expect(File('${output.path}/report.json').existsSync(), isTrue);
    expect(
      File('${output.path}/failures/shell/baseline.png').existsSync(),
      isTrue,
    );
    expect(
      File('${output.path}/failures/shell/actual.png').existsSync(),
      isTrue,
    );
    expect(File('${output.path}/failures/shell/diff.png').existsSync(), isTrue);
  });
}

image.Image _solidImage(
  int width,
  int height, {
  required int red,
  required int green,
  required int blue,
}) {
  final result = image.Image(width: width, height: height);
  image.fill(result, color: image.ColorRgb8(red, green, blue));
  return result;
}
