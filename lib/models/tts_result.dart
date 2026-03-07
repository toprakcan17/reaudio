class SentenceTimestamp {
  final int sentenceIndex;
  final String text;
  final Duration start;
  final Duration end;

  const SentenceTimestamp({
    required this.sentenceIndex,
    required this.text,
    required this.start,
    required this.end,
  });
}

class TtsResult {
  final String audioFilePath;
  final List<SentenceTimestamp> timestamps;
  final String chapterTitle;

  const TtsResult({
    required this.audioFilePath,
    required this.timestamps,
    required this.chapterTitle,
  });
}

enum TtsJobStatus { pending, processing, completed, failed }

class TtsJob {
  final String id;
  final String bookTitle;
  final String chapterTitle;
  final int chapterIndex;
  TtsJobStatus status;
  TtsResult? result;
  String? errorMessage;

  TtsJob({
    required this.id,
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterIndex,
    this.status = TtsJobStatus.pending,
    this.result,
    this.errorMessage,
  });
}
