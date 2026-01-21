import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/snap/data/snap_repository.dart';
import '../services/notification_service.dart';

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  final Connectivity _connectivity = Connectivity();
  final SnapRepository _snapRepository = SnapRepository();
  final NotificationService _notificationService = NotificationService();

  static const String _queueKey = 'snap_offline_queue';
  bool _isProcessing = false;

  /// Initialize and start listening to connectivity changes
  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        processQueue();
      }
    });
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Add a snap request to the offline queue
  Future<void> addToQueue({
    required String text,
    required String grade,
    required String subject,
    String language = 'en',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];

    final request = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text,
      'grade': grade,
      'subject': subject,
      'language': language,
      'timestamp': DateTime.now().toIso8601String(),
    };

    queue.add(jsonEncode(request));
    await prefs.setStringList(_queueKey, queue);
    debugPrint(
        '📦 Added Snap request to offline queue. Total: ${queue.length}');
  }

  /// Process queued requests
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_queueKey) ?? [];

      if (queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('🔄 Processing offline queue: ${queue.length} items');

      final List<String> remainingQueue = [];

      for (final itemStr in queue) {
        try {
          final item = jsonDecode(itemStr);
          // Try to solve the problem
          final solution = await _snapRepository.solveProblem(
            text: item['text'],
            grade: item['grade'],
            subject: item['subject'],
            language: item['language'],
          );

          // Save to library automatically
          await _snapRepository.saveSnap(
            title: "Offline Snap ${DateTime.now().toString().substring(0, 16)}",
            content: solution['solution_markdown'] ?? '',
            subject: item['subject'],
            grade: item['grade'],
          );

          // On success, notify user with solution data
          await _notificationService.showLocalNotification(
            id: int.parse(item['id'].toString().substring(8)),
            title: 'Snap Solved!',
            body:
                'Your offline snap request has been processed. Tap to view solution.',
            payload: jsonEncode({
              'type': 'snap_solution',
              'solution': solution,
              'text': item['text'],
            }),
          );

          // Also save it to library automatically as it was an async request?
          // For now just notifying.
        } catch (e) {
          debugPrint('❌ Failed to process queued item: $e');
          // Decide whether to keep it or discard.
          // For now, if it fails (e.g. server error), maybe keep it?
          // But if it's a persistent error we don't want to loop.
          // Let's assume transient network issues are handled by the check above.
          // If it fails here, it might be a server error. Let's keep it for retry later?
          // Or strictly, if we are "online" but it fails, maybe discard to avoid loop.
          // Let's keep it simple: failed items stay in queue for next retry.
          remainingQueue.add(itemStr);
        }
      }

      await prefs.setStringList(_queueKey, remainingQueue);
    } catch (e) {
      debugPrint('❌ Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
