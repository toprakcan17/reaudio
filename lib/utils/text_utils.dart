final _sentenceEndPattern = RegExp(r'(?<=[.!?])\s+');
final _whitespacePattern = RegExp(r'\s+');

List<String> splitIntoSentences(String text) {
  final cleaned = cleanText(text);
  if (cleaned.isEmpty) return [];

  return cleaned
      .split(_sentenceEndPattern)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String cleanText(String text) {
  return text
      .replaceAll(_whitespacePattern, ' ')
      .replaceAll(RegExp(r'[\u00ad\u200b\ufeff]'), '') // soft hyphens, zero-width chars
      .trim();
}

List<String> chunkSentences(List<String> sentences, {int maxChars = 4000}) {
  final chunks = <String>[];
  final buffer = StringBuffer();

  for (final sentence in sentences) {
    if (buffer.length + sentence.length + 1 > maxChars && buffer.isNotEmpty) {
      chunks.add(buffer.toString().trim());
      buffer.clear();
    }
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(sentence);
  }

  if (buffer.isNotEmpty) chunks.add(buffer.toString().trim());
  return chunks;
}
