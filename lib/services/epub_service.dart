import 'dart:io';
import 'package:epubx/epubx.dart';
import '../models/book.dart';
import '../utils/text_utils.dart';

Future<Book> parseEpub(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  final epub = await EpubReader.readBook(bytes);

  final chapters = <Chapter>[];
  int index = 0;

  for (final chapter in epub.Chapters ?? []) {
    final text = _extractChapterText(chapter);
    if (text.trim().isEmpty) continue;

    chapters.add(Chapter(
      title: chapter.Title ?? 'Chapter ${index + 1}',
      index: index,
      sentences: splitIntoSentences(text),
    ));
    index++;

    for (final sub in chapter.SubChapters ?? []) {
      final subText = _extractChapterText(sub);
      if (subText.trim().isEmpty) continue;
      chapters.add(Chapter(
        title: sub.Title ?? 'Chapter ${index + 1}',
        index: index,
        sentences: splitIntoSentences(subText),
      ));
      index++;
    }
  }

  return Book(
    title: epub.Title ?? _titleFromPath(filePath),
    author: epub.Author,
    filePath: filePath,
    format: BookFormat.epub,
    chapters: chapters,
  );
}

String _extractChapterText(EpubChapter chapter) {
  final content = chapter.HtmlContent ?? '';
  // Strip HTML tags
  return content
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'&nbsp;'), ' ')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'&lt;'), '<')
      .replaceAll(RegExp(r'&gt;'), '>')
      .replaceAll(RegExp(r'&quot;'), '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _titleFromPath(String path) {
  final name = path.split('/').last;
  return name.endsWith('.epub') ? name.substring(0, name.length - 5) : name;
}
