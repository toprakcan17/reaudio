import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';

class BookCacheService {
  static const _dbName = 'audiobook_cache.db';
  static const _dbVersion = 1;
  static const _chunkSize = 500;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        filePath TEXT NOT NULL UNIQUE,
        format TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        chapterIndex INTEGER NOT NULL,
        title TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE sentences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapterId INTEGER NOT NULL,
        orderIndex INTEGER NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY (chapterId) REFERENCES chapters(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_chapters_book ON chapters(bookId)',
    );
    await db.execute(
      'CREATE INDEX idx_sentences_chapter ON sentences(chapterId)',
    );
  }

  Future<void> saveBook(Book book) async {
    final db = await database;
    await db.transaction((txn) async {
      // Remove existing entry for same file path
      final existing = await txn.query(
        'books',
        columns: ['id'],
        where: 'filePath = ?',
        whereArgs: [book.filePath],
      );
      if (existing.isNotEmpty) {
        await _deleteBookById(txn, existing.first['id'] as int);
      }

      final bookId = await txn.insert('books', {
        'title': book.title,
        'author': book.author,
        'filePath': book.filePath,
        'format': book.format.name,
      });

      for (final chapter in book.chapters) {
        final chapterId = await txn.insert('chapters', {
          'bookId': bookId,
          'chapterIndex': chapter.index,
          'title': chapter.title,
        });

        // Write sentences in chunks
        for (var i = 0; i < chapter.sentences.length; i += _chunkSize) {
          final end = (i + _chunkSize).clamp(0, chapter.sentences.length);
          final batch = txn.batch();
          for (var j = i; j < end; j++) {
            batch.insert('sentences', {
              'chapterId': chapterId,
              'orderIndex': j,
              'text': chapter.sentences[j],
            });
          }
          await batch.commit(noResult: true);
        }
      }
    });
  }

  Future<List<Book>> loadBooks() async {
    final db = await database;
    final bookRows = await db.query('books', orderBy: 'id ASC');

    final books = <Book>[];
    for (final bookRow in bookRows) {
      final bookId = bookRow['id'] as int;
      final chapterRows = await db.query(
        'chapters',
        where: 'bookId = ?',
        whereArgs: [bookId],
        orderBy: 'chapterIndex ASC',
      );

      final chapters = <Chapter>[];
      for (final chapterRow in chapterRows) {
        final chapterId = chapterRow['id'] as int;

        // Read sentences in chunks
        final sentences = <String>[];
        var offset = 0;
        while (true) {
          final rows = await db.query(
            'sentences',
            columns: ['text'],
            where: 'chapterId = ?',
            whereArgs: [chapterId],
            orderBy: 'orderIndex ASC',
            limit: _chunkSize,
            offset: offset,
          );
          if (rows.isEmpty) break;
          sentences.addAll(rows.map((r) => r['text'] as String));
          if (rows.length < _chunkSize) break;
          offset += _chunkSize;
        }

        chapters.add(Chapter(
          title: chapterRow['title'] as String,
          index: chapterRow['chapterIndex'] as int,
          sentences: sentences,
        ));
      }

      books.add(Book(
        title: bookRow['title'] as String,
        author: bookRow['author'] as String?,
        filePath: bookRow['filePath'] as String,
        format: BookFormat.values.byName(bookRow['format'] as String),
        chapters: chapters,
      ));
    }
    return books;
  }

  Future<void> deleteBook(String filePath) async {
    final db = await database;
    final rows = await db.query(
      'books',
      columns: ['id'],
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
    if (rows.isNotEmpty) {
      await _deleteBookById(db, rows.first['id'] as int);
    }
  }

  Future<void> _deleteBookById(DatabaseExecutor db, int bookId) async {
    final chapters = await db.query(
      'chapters',
      columns: ['id'],
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    for (final ch in chapters) {
      await db.delete(
        'sentences',
        where: 'chapterId = ?',
        whereArgs: [ch['id']],
      );
    }
    await db.delete('chapters', where: 'bookId = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }
}
