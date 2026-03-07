import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/player_status.dart';
import '../services/tts_service.dart';

class PlayerScreen extends StatefulWidget {
  final Book book;

  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _chapterIndex = 0;
  int? _currentSentenceIndex;
  PlayerStatus _playerStatus = PlayerStatus.stopped;
  final TtsService _ttsService = TtsService();
  bool _showChapterList = true;

  Chapter get _currentChapter => widget.book.chapters[_chapterIndex];

  @override
  void initState() {
    super.initState();
    _ttsService.onComplete = _onSentenceComplete;
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _selectChapter(int index) {
    _ttsService.stop();
    setState(() {
      _chapterIndex = index;
      _currentSentenceIndex = null;
      _playerStatus = PlayerStatus.stopped;
    });
  }

  void _selectSentence(int index) {
    final wasPlaying = _playerStatus == PlayerStatus.running;
    _ttsService.stop();
    setState(() {
      _currentSentenceIndex = index;
    });
    if (wasPlaying) {
      _startPlayback();
    }
  }

  void _togglePlayPause() {
    if (_playerStatus == PlayerStatus.running) {
      _ttsService.stop();
      setState(() {
        _playerStatus = PlayerStatus.paused;
      });
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    final sentences = _currentChapter.sentences;
    if (sentences.isEmpty) return;

    final index = _currentSentenceIndex ?? 0;
    setState(() {
      _currentSentenceIndex = index;
      _playerStatus = PlayerStatus.running;
    });
    _ttsService.speak(sentences[index]);
  }

  void _onSentenceComplete() {
    if (_playerStatus != PlayerStatus.running) return;

    final sentences = _currentChapter.sentences;
    final nextIndex = (_currentSentenceIndex ?? 0) + 1;

    if (nextIndex < sentences.length) {
      setState(() {
        _currentSentenceIndex = nextIndex;
      });
      _ttsService.speak(sentences[nextIndex]);
    } else if (_chapterIndex + 1 < widget.book.chapters.length) {
      _chapterIndex++;
      _currentSentenceIndex = 0;
      final newSentences = _currentChapter.sentences;
      if (newSentences.isNotEmpty) {
        setState(() {});
        _ttsService.speak(newSentences[0]);
      } else {
        setState(() {
          _playerStatus = PlayerStatus.stopped;
        });
      }
    } else {
      setState(() {
        _playerStatus = PlayerStatus.stopped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    if (_showChapterList)
                      _ChapterList(
                        chapters: widget.book.chapters,
                        selectedIndex: _chapterIndex,
                        onSelect: _selectChapter,
                      )
                    else
                      _CollapsedChapterList(
                        chapters: widget.book.chapters,
                        selectedIndex: _chapterIndex,
                        onSelect: _selectChapter,
                      ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          _ChapterHeader(chapter: _currentChapter),
                          Expanded(
                            child: _SentenceList(
                              chapter: _currentChapter,
                              selectedIndex: _currentSentenceIndex,
                              onSelect: _selectSentence,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'chapterToggle',
                    onPressed: () {
                      setState(() {
                        _showChapterList = !_showChapterList;
                      });
                    },
                    tooltip: _showChapterList
                        ? 'Hide chapters'
                        : 'Show chapters',
                    child: Icon(
                      _showChapterList
                          ? Icons.menu_open
                          : Icons.menu,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _PlayerBar(
            status: _playerStatus,
            onTogglePlayPause: _togglePlayPause,
            currentSentence: _currentSentenceIndex != null
                ? _currentChapter.sentences[_currentSentenceIndex!]
                : null,
          ),
        ],
      ),
    );
  }
}

class _ChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ChapterList({
    required this.chapters,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (_, i) => ListTile(
          selected: i == selectedIndex,
          dense: true,
          title: Text(
            chapters[i].title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${chapters[i].sentences.length} sentences'),
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final Chapter chapter;
  const _ChapterHeader({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(chapter.title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final PlayerStatus status;
  final VoidCallback onTogglePlayPause;
  final String? currentSentence;

  const _PlayerBar({
    required this.status,
    required this.onTogglePlayPause,
    this.currentSentence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              status == PlayerStatus.running
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
            ),
            iconSize: 40,
            onPressed: onTogglePlayPause,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentSentence ?? 'Select a sentence to play',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceList extends StatelessWidget {
  final Chapter chapter;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _SentenceList({
    required this.chapter,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: chapter.sentences.length,
      itemBuilder: (_, i) {
        final isSelected = i == selectedIndex;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => onSelect(i),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(chapter.sentences[i]),
            ),
          ),
        );
      },
    );
  }
}

class _CollapsedChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CollapsedChapterList({
    required this.chapters,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (_, i) {
          final isSelected = i == selectedIndex;
          return InkWell(
            onTap: () => onSelect(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
