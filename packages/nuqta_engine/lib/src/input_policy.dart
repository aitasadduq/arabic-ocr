import 'dart:math' as math;

/// The model's input rule (nuqta-ocr `src/nuqta/preprocess.py`):
///
/// * page-shaped images (aspect <= 2, short side >= 450 px) are scaled to the
///   target size, up or down;
/// * everything else (words, lines, cards) keeps its size;
/// * every image is capped at the target size.
///
/// The model was trained at 2.4 MP. 1 MP is the upstream apps' "faster" setting.
abstract final class NuqtaInputPolicy {
  static const double accurateMegapixels = 2.4;
  static const double fastMegapixels = 1.0;

  static const int pageMinShortSide = 450;
  static const double pageMaxAspect = 2.0;

  static bool isPage(int width, int height) {
    final short = math.min(width, height), long = math.max(width, height);
    return short >= pageMinShortSide &&
        long / math.max(short, 1) <= pageMaxAspect;
  }

  /// The size an image of [width] x [height] should be given to the model at.
  static ({int width, int height}) targetSize(
    int width,
    int height, {
    double megapixels = accurateMegapixels,
  }) {
    final area = width * height;
    final target = megapixels * 1e6;
    if (area <= 0) return (width: width, height: height);
    if (area > target || isPage(width, height)) {
      final k = math.sqrt(target / area);
      return (
        width: math.max(32, (width * k).round()),
        height: math.max(32, (height * k).round()),
      );
    }
    return (width: width, height: height);
  }

  /// PDF pages are rendered at this resolution before [targetSize] is applied.
  static const double pdfDpi = 200;
}
