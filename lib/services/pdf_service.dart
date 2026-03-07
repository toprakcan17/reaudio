import '../models/book.dart';
import '../utils/text_utils.dart';

// PDF parsing requires a native plugin. This is a stub that will be
// implemented once a suitable PDF package is added to pubspec.yaml.
// Recommended: syncfusion_flutter_pdf or pdfx for text extraction.
Future<Book> parsePdf(String filePath) async {
  throw UnimplementedError(
    'PDF parsing not yet implemented. '
    'Add a PDF text extraction package (e.g. syncfusion_flutter_pdf) to pubspec.yaml.',
  );
}

/// Splits raw PDF text into chapters heuristically by detecting headings.
List<Chapter> _splitIntoChapters(String fullText) {
  // Simple heuristic: treat lines that are short, uppercase, or match
  // "Chapter N" as chapter headings.
  final headingPattern = RegExp(
    r'^(chapter\s+\d+|part\s+\d+|section\s+\d+)',
    caseSensitive: false,
  );

  final lines = fullText.split('\n');
  final rawChapters = <(String, StringBuffer)>[];
  String currentTitle = 'Introduction';
  StringBuffer currentBuffer = StringBuffer();

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    if (headingPattern.hasMatch(trimmed) ||
        (trimmed.length < 60 && trimmed == trimmed.toUpperCase() && trimmed.length > 3)) {
      if (currentBuffer.isNotEmpty) {
        rawChapters.add((currentTitle, currentBuffer));
      }
      currentTitle = trimmed;
      currentBuffer = StringBuffer();
    } else {
      if (currentBuffer.isNotEmpty) currentBuffer.write(' ');
      currentBuffer.write(trimmed);
    }
  }

  if (currentBuffer.isNotEmpty) {
    rawChapters.add((currentTitle, currentBuffer));
  }

  return rawChapters.indexed
      .map((e) => Chapter(
            title: e.$2.$1,
            index: e.$1,
            sentences: splitIntoSentences(e.$2.$2.toString()),
          ))
      .toList();
}
