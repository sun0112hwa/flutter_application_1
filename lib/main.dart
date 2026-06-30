import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NotificationReaderPage(),
    );
  }
}

class NotificationReaderPage extends StatefulWidget {
  const NotificationReaderPage({super.key});

  @override
  State<NotificationReaderPage> createState() => _NotificationReaderPageState();
}

class _NotificationReaderPageState extends State<NotificationReaderPage> {
  static const _methodChannel = MethodChannel('com.example.flutter_application_1/notification_methods');
  static const _eventChannel = EventChannel('com.example.flutter_application_1/notification_events');

  final List<Map<String, dynamic>> _notifications = [];
  bool _accessGranted = false;
  StreamSubscription<dynamic>? _subscription;
  
  // MongoDB 백엔드 URL (로컬 개발용)
  static const String _backendUrl = 'http://10.0.2.2:3000/api/notifications';

  @override
  void initState() {
    super.initState();
    _checkNotificationAccess();
    _subscribeNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _saveToMongoDB(Map<String, String> notification) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': notification['title'] ?? '',
          'text': notification['text'] ?? '',
          'package': notification['package'] ?? '',
          'timestamp': DateTime.now().toIso8601String(),
          'formattedTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('✓ Notification saved to MongoDB');
      } else {
        debugPrint('✗ Failed to save to MongoDB: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving to MongoDB: $e');
    }
  }

  Future<void> _checkNotificationAccess() async {
    final granted = await _methodChannel.invokeMethod<bool>('isNotificationAccessGranted');
    if (mounted) {
      setState(() {
        _accessGranted = granted == true;
      });
    }
  }

  void _subscribeNotifications() {
    _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final payload = Map<String, String>.from(event.cast<String, String>());
        
        // MongoDB에 저장
        _saveToMongoDB(payload);
        
        setState(() {
          _notifications.insert(0, {
            ...payload,
            'timestamp': DateTime.now().toIso8601String(),
            'formattedTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          });
          if (_notifications.length > 20) {
            _notifications.removeLast();
          }
        });
      }
    }, onError: (error) {
      debugPrint('Notification stream error: $error');
    });
  }

  Future<void> _openSettings() async {
    await _methodChannel.invokeMethod('openNotificationAccessSettings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KakaoTalk 알림 리더'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _accessGranted ? '알림 접근 권한이 허용되었습니다.' : '알림 접근 권한을 허용해주세요.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _openSettings,
                child: const Text('알림 접근 권한 설정 열기'),
              ),
              const SizedBox(height: 20),
              const Text('최근 카카오톡 알림', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(child: Text('아직 수신된 알림이 없습니다.'))
                    : ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return ListTile(
                            title: Text(notification['title'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['text'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  notification['formattedTime'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Text(notification['package'] ?? ''),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
