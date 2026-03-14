import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_cache_service.dart';
import '../services/epub_service.dart';
import '../services/pdf_service.dart';
import 'player_screen.dart';
import 'browse_books_screen.dart';
import 'settings_screen.dart';
import '../main.dart';
import '../models/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Book> _books = [];
  final BookCacheService _cache = BookCacheService();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedBooks();
  }

  Future<void> _loadCachedBooks() async {
    setState(() => _loading = true);
    try {
      final books = await _cache.loadBooks();
      setState(() => _books.addAll(books));
    } catch (e) {
      setState(() => _error = 'Failed to load cached books: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Book book;
      if (path.endsWith('.epub')) {
        book = await parseEpub(path);
      } else {
        book = await parsePdf(path);
      }
      await _cache.saveBook(book);
      setState(() => _books.add(book));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audiobook TTS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Get New Books',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BrowseBooksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              final appState = AudiobookApp.of(context);
              final result = await Navigator.push<AppSettings>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(settings: appState.settings),
                ),
              );
              if (result != null) {
                appState.updateSettings(result);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _books.isEmpty
                ? const Center(
                    child: Text(
                      'No books yet.\nTap + to add an EPUB or PDF.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _books.length,
                    itemBuilder: (_, i) {
                      final book = _books[i];
                      return ListTile(
                        leading: Icon(
                          book.format == BookFormat.epub
                              ? Icons.menu_book
                              : Icons.picture_as_pdf,
                        ),
                        title: Text(book.title),
                        subtitle: Text(
                          [
                            if (book.author != null) book.author!,
                            '${book.chapters.length} chapters',
                            '${book.totalSentences} sentences',
                          ].join(' · '),
                        ),
                        onTap: () => _openBook(book),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _pickFile,
        tooltip: 'Add book',
        child: const Icon(Icons.add),
      ),
    );
  }
}
