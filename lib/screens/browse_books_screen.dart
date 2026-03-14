import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';
import '../services/book_cache_service.dart';
import '../services/epub_service.dart';
import '../services/pdf_service.dart';

class _DownloadLink {
  final String format;
  final String size;
  final String url;

  const _DownloadLink({
    required this.format,
    required this.size,
    required this.url,
  });
}

class _BookResult {
  final String identifier;
  final String title;
  final String? creator;
  final int? year;

  const _BookResult({
    required this.identifier,
    required this.title,
    this.creator,
    this.year,
  });

  String get imageUrl => 'https://archive.org/services/img/$identifier';
}

class BrowseBooksScreen extends StatefulWidget {
  const BrowseBooksScreen({super.key});

  @override
  State<BrowseBooksScreen> createState() => _BrowseBooksScreenState();
}

class _BrowseBooksScreenState extends State<BrowseBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_BookResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final uri =
          Uri.https('archive.org', '/services/search/beta/page_production/', {
            'user_query': query,
            'page_type': 'collection_details',
            'page_target': 'texts',
            'hits_per_page': '20',
            'page': '1',
            'aggregations': 'false',
          });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        setState(() => _error = 'Request failed: ${response.statusCode}');
        return;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final hits = (json['response']?['body']?['hits']?['hits'] as List?) ?? [];

      final results = <_BookResult>[];
      for (final hit in hits) {
        final fields = hit['fields'] as Map<String, dynamic>?;
        if (fields == null) continue;

        final mediatype = fields['mediatype'] as String?;
        if (mediatype != 'texts') continue;

        final identifier = fields['identifier'] as String?;
        final title = fields['title'] as String?;
        if (identifier == null || title == null) continue;

        final creatorRaw = fields['creator'];
        String? creator;
        if (creatorRaw is List && creatorRaw.isNotEmpty) {
          creator = creatorRaw.first.toString();
        } else if (creatorRaw is String) {
          creator = creatorRaw;
        }

        results.add(
          _BookResult(
            identifier: identifier,
            title: title,
            creator: creator,
            year: fields['year'] as int?,
          ),
        );
      }

      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<_DownloadLink>> _fetchDownloadLinks(String identifier) async {
    final uri = Uri.https('archive.org', '/details/$identifier');
    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    );

    if (response.statusCode != 200) return [];

    final document = html_parser.parse(response.body);
    final anchors = document.querySelectorAll('a.format-summary.download-pill');
    final results = <_DownloadLink>[];

    for (final anchor in anchors) {
      final href = anchor.attributes['href'] ?? '';
      final size = anchor.attributes['title'] ?? '';
      final format = anchor.text
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(' download', '')
          .trim();
      if (format == 'PDF' || format == 'EPUB') {
        results.add(
          _DownloadLink(
            format: format,
            size: size,
            url: 'https://archive.org$href',
          ),
        );
      }
    }

    return results;
  }

  void _showBookDetails(_BookResult book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _BookDetailSheet(
          book: book,
          fetchLinks: () => _fetchDownloadLinks(book.identifier),
          onBookImported: (importedBook) {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${importedBook.title} imported!')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get New Books'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books on Archive.org...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _error = null;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_loading
                ? const Center(child: Text('Search for books to get started.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final result = _results[i];
                      return ListTile(
                        leading: Image.network(
                          result.imageUrl,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 48),
                        ),
                        title: Text(
                          result.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            if (result.creator != null) result.creator!,
                            if (result.year != null) '${result.year}',
                          ].join(' · '),
                        ),
                        onTap: () => _showBookDetails(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookDetailSheet extends StatefulWidget {
  final _BookResult book;
  final Future<List<_DownloadLink>> Function() fetchLinks;
  final void Function(Book book) onBookImported;

  const _BookDetailSheet({
    required this.book,
    required this.fetchLinks,
    required this.onBookImported,
  });

  @override
  State<_BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<_BookDetailSheet> {
  List<_DownloadLink>? _links;
  bool _loadingLinks = true;
  String? _downloadingFormat;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final links = await widget.fetchLinks();
    if (mounted) {
      setState(() {
        _links = links;
        _loadingLinks = false;
      });
    }
  }

  Future<void> _download(_DownloadLink link) async {
    setState(() {
      _downloadingFormat = link.format;
      _downloadError = null;
    });

    try {
      final request = http.Request('GET', Uri.parse(link.url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

      final client = http.Client();
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        client.close();
        if (mounted) {
          setState(() {
            _downloadError = 'Download failed: ${streamedResponse.statusCode}';
            _downloadingFormat = null;
          });
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final ext = link.format == 'EPUB' ? 'epub' : 'pdf';
      final fileName = '${widget.book.identifier}.$ext'.replaceAll(
        RegExp(r'[^\w\.\-]'),
        '_',
      );
      final filePath = p.join(dir.path, fileName);

      final file = File(filePath);
      final sink = file.openWrite();
      await streamedResponse.stream.pipe(sink);
      await sink.close();
      client.close();

      final Book book;
      if (ext == 'epub') {
        book = await parseEpub(filePath);
      } else {
        book = await parsePdf(filePath);
      }

      final cache = BookCacheService();
      await cache.saveBook(book);

      if (mounted) {
        widget.onBookImported(book);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadError = e.toString();
          _downloadingFormat = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.5,
      minChildSize: 0.25,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.book.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (widget.book.creator != null)
                Text(
                  widget.book.creator!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (widget.book.year != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${widget.book.year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Download',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _downloadError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_loadingLinks)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_links == null || _links!.isEmpty)
                Text(
                  'No PDF or EPUB downloads available.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...(_links!.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: _downloadingFormat != null
                          ? null
                          : () => _download(link),
                      icon: _downloadingFormat == link.format
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              link.format == 'EPUB'
                                  ? Icons.menu_book
                                  : Icons.picture_as_pdf,
                            ),
                      label: Text(
                        _downloadingFormat == link.format
                            ? 'Downloading...'
                            : '${link.format}  (${link.size})',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}
