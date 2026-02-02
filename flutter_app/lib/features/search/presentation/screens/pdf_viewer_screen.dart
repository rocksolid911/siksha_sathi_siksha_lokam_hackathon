import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shiksha_saathi/core/constants/app_colors.dart';
import 'package:shiksha_saathi/core/constants/app_text_styles.dart';
import 'package:shiksha_saathi/features/library/data/library_repository.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String errorMessage = '';
  bool isSaving = false;
  bool isSaved = false;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      // Use a common browser User-Agent to avoid being blocked by WAFs
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      };

      final response = await http.get(Uri.parse(widget.url), headers: headers);

      if (response.statusCode == 200) {
        // Check content type if possible, or response body size
        if (response.headers['content-type'] != null &&
            !response.headers['content-type']!.toLowerCase().contains('pdf') &&
            !response.headers['content-type']!
                .toLowerCase()
                .contains('application/octet-stream')) {
          print('Warning: Content-Type is ${response.headers['content-type']}');
          // Proceed anyway but might fail
        }

        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Could not load PDF: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveToLibrary() async {
    setState(() {
      isSaving = true;
    });

    try {
      final repository = LibraryRepository(); // Ideally inject via Bloc
      // We pass the PDF URL as the 'content' or 'video_url' depending on schema
      // Here we map it to content/video_url for now, or use a specific field if available
      // Using 'video_url' field for PDF link as a hack or 'content' field if purely text
      // Let's us 'video_url' to store the external link for now as per schema flexibility

      final response = await repository.saveResource({
        'title': widget.title,
        'title_hi': widget.title, // Fallback
        'video_url': widget.url, // Store Link here
        'content': 'PDF Resource: ${widget.url}',
        'subject': 'General',
        'grade': 'All',
        'resource_type': 'pdf'
      });

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            isSaved = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.resourceSaved)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToSave)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: AppTextStyles.bodyLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    isSaved ? LucideIcons.check : LucideIcons.bookmarkPlus,
                    color: isSaved ? AppColors.primary : Colors.black,
                  ),
            onPressed: (isSaving || isSaved) ? null : _saveToLibrary,
            tooltip: isSaved
                ? AppLocalizations.of(context)!.resourceSaved
                : AppLocalizations.of(context)!.saveToLibrary,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (localPath != null)
            PDFView(
              filePath: localPath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              onError: (error) {
                print(error.toString());
              },
              onPageError: (page, error) {
                print('$page: ${error.toString()}');
              },
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page!;
                });
              },
            ),
          if (_totalPages > 0)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(errorMessage,
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}
