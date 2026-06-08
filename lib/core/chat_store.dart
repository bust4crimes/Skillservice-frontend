// lib/core/chat_store.dart
import 'package:hive/hive.dart';

class ChatStore {
  static const _boxName = 'chat_messages';

  static Future<void> saveMessage(String conversationId, Map<String, dynamic> message) async {
    final box = Hive.box(_boxName);
    final key = 'conv_$conversationId';
    final list = List<Map<String, dynamic>>.from(box.get(key, defaultValue: []) ?? []);
    list.add(message);
    await box.put(key, list);
  }

  static List<Map<String, dynamic>> loadConversation(String conversationId) {
    final box = Hive.box(_boxName);
    final key = 'conv_$conversationId';
    final list = box.get(key, defaultValue: []) as List<dynamic>;
    return List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e)));
  }
}
