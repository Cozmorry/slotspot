import 'dart:io';
import 'package:image/image.dart' as img;

// Generates a padded splash image from an input PNG, centered with margins
// Usage: dart run tool/generate_padded_splash.dart <input_png> <output_png>
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/generate_padded_splash.dart <input_png> <output_png>');
    exit(64);
  }
  final inputPath = args[0];
  final outputPath = args[1];

  final bytes = await File(inputPath).readAsBytes();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode $inputPath');
    exit(1);
  }

  // Create square canvas 1024x1024
  const int size = 1024;
  // Transparent canvas (pixels default to 0x00000000)
  final canvas = img.Image(width: size, height: size);

  // Scale source to ~70% of canvas width preserving aspect ratio
  final targetW = (size * 0.7).round();
  final scale = targetW / src.width;
  final targetH = (src.height * scale).round();
  final resized = img.copyResize(src, width: targetW, height: targetH, interpolation: img.Interpolation.cubic);

  // Center
  final dx = ((size - resized.width) / 2).round();
  final dy = ((size - resized.height) / 2).round();
  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

  await File(outputPath).writeAsBytes(img.encodePng(canvas));
  stdout.writeln('Wrote padded splash to $outputPath');
}


