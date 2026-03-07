enum BookFormat { epub, pdf }

class Chapter {
  final String title;
  final int index;
  final List<String> sentences;

  const Chapter({
    required this.title,
    required this.index,
    required this.sentences,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'index': index,
        'sentences': sentences,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        title: json['title'] as String,
        index: json['index'] as int,
        sentences: (json['sentences'] as List).cast<String>(),
      );
}

class Book {
  final String title;
  final String? author;
  final String filePath;
  final BookFormat format;
  final List<Chapter> chapters;

  const Book({
    required this.title,
    this.author,
    required this.filePath,
    required this.format,
    required this.chapters,
  });

  int get totalSentences =>
      chapters.fold(0, (sum, c) => sum + c.sentences.length);

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'filePath': filePath,
        'format': format.name,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        title: json['title'] as String,
        author: json['author'] as String?,
        filePath: json['filePath'] as String,
        format: BookFormat.values.byName(json['format'] as String),
        chapters: (json['chapters'] as List)
            .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
