/*
 * 清源视觉回归比较器 — 逐图计算应用区域与外部区域 SSIM
 * @Project : SSPU-AllinOne
 * @File : visual_compare.dart
 * @Author : Qintsg
 * @Date : 2026-07-18
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;

const int _windowSize = 8;
const int _ssimPrefilterRadius = 5;

class VisualRegion {
  const VisualRegion({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory VisualRegion.fromJson(Map<String, Object?> json) => VisualRegion(
    id: json['id']! as String,
    x: json['x']! as int,
    y: json['y']! as int,
    width: json['width']! as int,
    height: json['height']! as int,
  );

  final String id;
  final int x;
  final int y;
  final int width;
  final int height;

  bool contains(int px, int py) =>
      px >= x && px < x + width && py >= y && py < y + height;

  Map<String, Object> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class VisualRegionScore {
  const VisualRegionScore({
    required this.region,
    required this.ssim,
    required this.threshold,
  });

  final VisualRegion region;
  final double ssim;
  final double threshold;

  bool get passed => ssim >= threshold;

  Map<String, Object> toJson() => {
    ...region.toJson(),
    'ssim': ssim,
    'threshold': threshold,
    'passed': passed,
  };
}

class VisualComparison {
  const VisualComparison({
    required this.applicationSsim,
    required this.applicationThreshold,
    required this.externalRegions,
    required this.heatmap,
  });

  final double applicationSsim;
  final double applicationThreshold;
  final List<VisualRegionScore> externalRegions;
  final image.Image heatmap;

  bool get passed =>
      applicationSsim >= applicationThreshold &&
      externalRegions.every((region) => region.passed);

  Map<String, Object> toJson() => {
    'application': {
      'ssim': applicationSsim,
      'threshold': applicationThreshold,
      'passed': applicationSsim >= applicationThreshold,
    },
    'externalRegions': externalRegions
        .map((region) => region.toJson())
        .toList(growable: false),
    'passed': passed,
  };
}

VisualComparison compareVisuals({
  required image.Image baseline,
  required image.Image actual,
  required double applicationThreshold,
  required double externalThreshold,
  List<VisualRegion> externalRegions = const [],
}) {
  if (baseline.width != actual.width || baseline.height != actual.height) {
    throw ArgumentError(
      '截图尺寸不一致：baseline=${baseline.width}x${baseline.height}, '
      'actual=${actual.width}x${actual.height}',
    );
  }
  for (final region in externalRegions) {
    if (region.x < 0 ||
        region.y < 0 ||
        region.width <= 0 ||
        region.height <= 0 ||
        region.x + region.width > baseline.width ||
        region.y + region.height > baseline.height) {
      throw ArgumentError('外部区域 ${region.id} 超出截图边界');
    }
  }

  // Chromium 与 Flutter/Skia 对同一字体会产生亚像素级抗锯齿差异。
  // SSIM 输入先做 5px 高斯低通，避免把字形边缘采样差异误判为布局变化；
  // 热图仍使用原始像素，确保真实偏移和色差可定位。
  final filteredBaseline = image.gaussianBlur(
    image.Image.from(baseline),
    radius: _ssimPrefilterRadius,
  );
  final filteredActual = image.gaussianBlur(
    image.Image.from(actual),
    radius: _ssimPrefilterRadius,
  );

  return VisualComparison(
    applicationSsim: _windowedSsim(
      filteredBaseline,
      filteredActual,
      excludedRegions: _expandedRegions(
        externalRegions,
        width: baseline.width,
        height: baseline.height,
        margin: _ssimPrefilterRadius,
      ),
    ),
    applicationThreshold: applicationThreshold,
    externalRegions: externalRegions
        .map(
          (region) => VisualRegionScore(
            region: region,
            ssim: _windowedSsim(
              filteredBaseline,
              filteredActual,
              includedRegion: _insetRegion(
                region,
                margin: _ssimPrefilterRadius,
              ),
            ),
            threshold: externalThreshold,
          ),
        )
        .toList(growable: false),
    heatmap: _createHeatmap(baseline, actual),
  );
}

List<VisualRegion> _expandedRegions(
  List<VisualRegion> regions, {
  required int width,
  required int height,
  required int margin,
}) => regions
    .map((region) {
      final x = math.max(0, region.x - margin);
      final y = math.max(0, region.y - margin);
      final right = math.min(width, region.x + region.width + margin);
      final bottom = math.min(height, region.y + region.height + margin);
      return VisualRegion(
        id: region.id,
        x: x,
        y: y,
        width: right - x,
        height: bottom - y,
      );
    })
    .toList(growable: false);

VisualRegion _insetRegion(VisualRegion region, {required int margin}) {
  final horizontalMargin = math.min(margin, (region.width - 1) ~/ 2);
  final verticalMargin = math.min(margin, (region.height - 1) ~/ 2);
  return VisualRegion(
    id: region.id,
    x: region.x + horizontalMargin,
    y: region.y + verticalMargin,
    width: region.width - horizontalMargin * 2,
    height: region.height - verticalMargin * 2,
  );
}

double _windowedSsim(
  image.Image baseline,
  image.Image actual, {
  VisualRegion? includedRegion,
  List<VisualRegion> excludedRegions = const [],
}) {
  final scores = <double>[];
  for (var startY = 0; startY < baseline.height; startY += _windowSize) {
    for (var startX = 0; startX < baseline.width; startX += _windowSize) {
      final reference = <double>[];
      final candidate = <double>[];
      final endY = math.min(startY + _windowSize, baseline.height);
      final endX = math.min(startX + _windowSize, baseline.width);
      for (var y = startY; y < endY; y += 1) {
        for (var x = startX; x < endX; x += 1) {
          if (includedRegion != null && !includedRegion.contains(x, y)) {
            continue;
          }
          if (excludedRegions.any((region) => region.contains(x, y))) {
            continue;
          }
          reference.add(_luminance(baseline.getPixel(x, y)));
          candidate.add(_luminance(actual.getPixel(x, y)));
        }
      }
      if (reference.isNotEmpty) {
        scores.add(_sampleSsim(reference, candidate));
      }
    }
  }
  if (scores.isEmpty) {
    throw ArgumentError('SSIM 区域没有可比较像素');
  }
  return scores.reduce((sum, score) => sum + score) / scores.length;
}

double _sampleSsim(List<double> reference, List<double> candidate) {
  final count = reference.length;
  final referenceMean = reference.reduce((a, b) => a + b) / count;
  final candidateMean = candidate.reduce((a, b) => a + b) / count;
  var referenceVariance = 0.0;
  var candidateVariance = 0.0;
  var covariance = 0.0;
  for (var index = 0; index < count; index += 1) {
    final referenceDelta = reference[index] - referenceMean;
    final candidateDelta = candidate[index] - candidateMean;
    referenceVariance += referenceDelta * referenceDelta;
    candidateVariance += candidateDelta * candidateDelta;
    covariance += referenceDelta * candidateDelta;
  }
  final divisor = math.max(1, count - 1);
  referenceVariance /= divisor;
  candidateVariance /= divisor;
  covariance /= divisor;

  final c1 = math.pow(0.01 * 255, 2).toDouble();
  final c2 = math.pow(0.03 * 255, 2).toDouble();
  final luminance =
      (2 * referenceMean * candidateMean + c1) /
      (referenceMean * referenceMean + candidateMean * candidateMean + c1);
  final structure =
      (2 * covariance + c2) / (referenceVariance + candidateVariance + c2);
  return (luminance * structure).clamp(-1.0, 1.0);
}

double _luminance(image.Pixel pixel) {
  final alpha = pixel.aNormalized;
  final red = pixel.r * alpha + 255 * (1 - alpha);
  final green = pixel.g * alpha + 255 * (1 - alpha);
  final blue = pixel.b * alpha + 255 * (1 - alpha);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

image.Image _createHeatmap(image.Image baseline, image.Image actual) {
  final heatmap = image.Image(width: baseline.width, height: baseline.height);
  for (var y = 0; y < baseline.height; y += 1) {
    for (var x = 0; x < baseline.width; x += 1) {
      final reference = baseline.getPixel(x, y);
      final candidate = actual.getPixel(x, y);
      final difference = math.max(
        (reference.r - candidate.r).abs(),
        math.max(
          (reference.g - candidate.g).abs(),
          (reference.b - candidate.b).abs(),
        ),
      );
      heatmap.setPixelRgba(x, y, difference, 0, 0, 255);
    }
  }
  return heatmap;
}

Future<int> runVisualComparison(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final manifest =
      jsonDecode(await File(options.manifest).readAsString())
          as Map<String, Object?>;
  final metadata = manifest['meta']! as Map<String, Object?>;
  final applicationThreshold = (metadata['applicationThreshold']! as num)
      .toDouble();
  final externalThreshold = (metadata['externalThreshold']! as num).toDouble();
  final platforms = (metadata['platforms']! as List<Object?>).cast<String>();
  if (!platforms.contains(options.platform)) {
    throw ArgumentError('视觉清单不包含平台 ${options.platform}');
  }

  final baselineRoot = Directory(options.baseline);
  final actualRoot = Directory(options.actual);
  final outputRoot = Directory(options.output)..createSync(recursive: true);
  final actualFiles =
      actualRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (actualFiles.isEmpty) {
    throw StateError('实际截图目录没有 PNG：${actualRoot.path}');
  }

  var allPassed = true;
  final results = <Map<String, Object?>>[];
  for (final actualFile in actualFiles) {
    final relative = _relativePath(actualRoot.path, actualFile.path);
    final baselineFile = File(
      '${baselineRoot.path}${Platform.pathSeparator}$relative',
    );
    if (!baselineFile.existsSync()) {
      allPassed = false;
      results.add({'image': relative, 'passed': false, 'error': '缺少基准图'});
      continue;
    }

    try {
      final baseline = image.decodePng(await baselineFile.readAsBytes());
      final actual = image.decodePng(await actualFile.readAsBytes());
      if (baseline == null || actual == null) {
        throw FormatException('PNG 解码失败');
      }
      final regions = await _readRegions(baselineFile);
      final comparison = compareVisuals(
        baseline: baseline,
        actual: actual,
        applicationThreshold: applicationThreshold,
        externalThreshold: externalThreshold,
        externalRegions: regions,
      );
      results.add({'image': relative, ...comparison.toJson()});
      if (!comparison.passed) {
        allPassed = false;
        await _writeFailureArtifacts(
          outputRoot: outputRoot,
          relativePath: relative,
          baselineFile: baselineFile,
          actualFile: actualFile,
          heatmap: comparison.heatmap,
        );
      }
    } on Object catch (error) {
      allPassed = false;
      results.add({'image': relative, 'passed': false, 'error': '$error'});
    }
  }

  final report = {
    'platform': options.platform,
    'applicationThreshold': applicationThreshold,
    'externalThreshold': externalThreshold,
    'passed': allPassed,
    'results': results,
  };
  await File(
    '${outputRoot.path}${Platform.pathSeparator}report.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(
    'Visual comparison ${allPassed ? 'passed' : 'failed'}: '
    '${results.length} image(s), platform=${options.platform}',
  );
  return allPassed ? 0 : 1;
}

Future<List<VisualRegion>> _readRegions(File baselineFile) async {
  final sidecar = File('${baselineFile.path}.regions.json');
  if (!sidecar.existsSync()) return const [];
  final json = jsonDecode(await sidecar.readAsString()) as Map<String, Object?>;
  final regions = json['externalRegions'] as List<Object?>? ?? const [];
  return regions
      .cast<Map<String, Object?>>()
      .map(VisualRegion.fromJson)
      .toList(growable: false);
}

Future<void> _writeFailureArtifacts({
  required Directory outputRoot,
  required String relativePath,
  required File baselineFile,
  required File actualFile,
  required image.Image heatmap,
}) async {
  final relativeDirectory = relativePath.substring(
    0,
    relativePath.length - '.png'.length,
  );
  final directory = Directory(
    '${outputRoot.path}${Platform.pathSeparator}failures'
    '${Platform.pathSeparator}$relativeDirectory',
  )..createSync(recursive: true);
  await baselineFile.copy(
    '${directory.path}${Platform.pathSeparator}baseline.png',
  );
  await actualFile.copy('${directory.path}${Platform.pathSeparator}actual.png');
  await File(
    '${directory.path}${Platform.pathSeparator}diff.png',
  ).writeAsBytes(image.encodePng(heatmap));
}

String _relativePath(String root, String path) {
  final normalizedRoot = Directory(root).absolute.path;
  final normalizedPath = File(path).absolute.path;
  return normalizedPath
      .substring(normalizedRoot.length + 1)
      .replaceAll('\\', '/');
}

class _Options {
  const _Options({
    required this.baseline,
    required this.actual,
    required this.output,
    required this.manifest,
    required this.platform,
  });

  final String baseline;
  final String actual;
  final String output;
  final String manifest;
  final String platform;
}

_Options _parseArguments(List<String> arguments) {
  String value(String name) {
    final index = arguments.indexOf(name);
    if (index == -1 || index + 1 >= arguments.length) {
      throw ArgumentError('缺少参数 $name');
    }
    return arguments[index + 1];
  }

  return _Options(
    baseline: value('--baseline'),
    actual: value('--actual'),
    output: value('--output'),
    manifest: value('--manifest'),
    platform: value('--platform'),
  );
}

Future<void> main(List<String> arguments) async {
  exitCode = await runVisualComparison(arguments);
}
