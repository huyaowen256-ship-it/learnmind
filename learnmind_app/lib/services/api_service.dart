import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/knowledge_card.dart';

/// API 基础地址（根据环境自动切换）
/// - 开发/真机：可通过 --dart-define=API_BASE=... 覆盖
const String _defaultApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8000/api',
);

String get API_BASE {
  // 优先读取 dart-define 环境变量，模拟器用 10.0.2.2，真机用局域网 IP
  return _defaultApiBase;
}

/// 认证信息（Phase 1 MVP 暂不启用）
const String API_TOKEN = '';

class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (API_TOKEN.isNotEmpty) 'Authorization': 'Bearer $API_TOKEN',
      };

  // ── 知识卡片 CRUD ──────────────────────────────────────

  Future<List<KnowledgeCard>> getKnowledgeCards({String? q, String? tag}) async {
    final uri = Uri.parse('$API_BASE/knowledge').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      },
    );

    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);

    final List data = jsonDecode(resp.body);
    return data.map((e) => KnowledgeCard.fromJson(e)).toList();
  }

  Future<KnowledgeCard> createCard(KnowledgeCard card) async {
    final resp = await _client.post(
      Uri.parse('$API_BASE/knowledge'),
      headers: _headers,
      body: jsonEncode({
        'title': card.title,
        'content': card.content,
        'tags': card.tags,
      }),
    );
    _checkResponse(resp);
    return KnowledgeCard.fromJson(jsonDecode(resp.body));
  }

  Future<KnowledgeCard> updateCard(String id, Map<String, dynamic> data) async {
    final resp = await _client.put(
      Uri.parse('$API_BASE/knowledge/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResponse(resp);
    return KnowledgeCard.fromJson(jsonDecode(resp.body));
  }

  Future<void> deleteCard(String id) async {
    final resp = await _client.delete(
      Uri.parse('$API_BASE/knowledge/$id'),
      headers: _headers,
    );
    if (resp.statusCode != 204) {
      _checkResponse(resp);
    }
  }

  // ── AI 对话 ────────────────────────────────────────────

  Future<ChatResult> explainCard(String cardId, {String? question, String level = '中等'}) async {
    final resp = await _client.post(
      Uri.parse('$API_BASE/chat/explain'),
      headers: _headers,
      body: jsonEncode({
        'card_id': cardId,
        'user_level': level,
        'custom_question': question,
      }),
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body);
    return ChatResult(
      sessionId: data['session_id'],
      message: data['message'],
    );
  }

  Future<ChatResult> followup(String cardId, String sessionId, String message) async {
    final resp = await _client.post(
      Uri.parse('$API_BASE/chat/followup'),
      headers: _headers,
      body: jsonEncode({
        'card_id': cardId,
        'session_id': sessionId,
        'message': message,
      }),
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body);
    return ChatResult(
      sessionId: data['session_id'],
      message: data['message'],
    );
  }

  Future<List<ChatMessage>> getChatHistory(String cardId) async {
    final resp = await _client.get(
      Uri.parse('$API_BASE/chat/history/$cardId'),
      headers: _headers,
    );
    _checkResponse(resp);
    final List data = jsonDecode(resp.body);
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  // ── 复习 ───────────────────────────────────────────────

  Future<ReviewDashboard> getTodayReviews() async {
    final resp = await _client.get(
      Uri.parse('$API_BASE/review/today'),
      headers: _headers,
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body);
    return ReviewDashboard.fromJson(data);
  }

  Future<ReviewQuestionSet> getReviewQuestions(String cardId) async {
    final resp = await _client.get(
      Uri.parse('$API_BASE/review/questions/$cardId'),
      headers: _headers,
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body);
    return ReviewQuestionSet.fromJson(data);
  }

  Future<ReviewResult> submitReview(String cardId, int quality) async {
    final resp = await _client.post(
      Uri.parse('$API_BASE/review/submit'),
      headers: _headers,
      body: jsonEncode({
        'card_id': cardId,
        'quality': quality,
      }),
    );
    _checkResponse(resp);
    return ReviewResult.fromJson(jsonDecode(resp.body));
  }

  // ── 统计 ───────────────────────────────────────────────

  Future<Stats> getStats() async {
    final resp = await _client.get(
      Uri.parse('$API_BASE/stats'),
      headers: _headers,
    );
    _checkResponse(resp);
    return Stats.fromJson(jsonDecode(resp.body));
  }

  // ── 错误处理 ────────────────────────────────────────────

  void _checkResponse(http.Response resp) {
    if (resp.statusCode >= 400) {
      String msg = '请求失败: ${resp.statusCode}';
      try {
        final body = jsonDecode(resp.body);
        msg = body['detail'] ?? msg;
      } catch (_) {}
      throw ApiException(msg);
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

// ── Provider ──────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── 对话结果模型 ──────────────────────────────────────────

class ChatResult {
  final String sessionId;
  final String message;
  ChatResult({required this.sessionId, required this.message});
}

/// 聊天历史消息
class ChatMessage {
  final String sessionId;
  final String role;
  final String content;
  final String createdAt;

  ChatMessage({
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        sessionId: json['session_id'] ?? '',
        role: json['role'] ?? '',
        content: json['content'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}

// ── 统计模型 ──────────────────────────────────────────────

class Stats {
  final int totalCards;
  final int dueToday;
  final int thisWeekNew;
  final int thisWeekReviewed;

  Stats({
    required this.totalCards,
    required this.dueToday,
    required this.thisWeekNew,
    required this.thisWeekReviewed,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        totalCards: json['total_cards'] ?? 0,
        dueToday: json['due_today'] ?? 0,
        thisWeekNew: json['this_week_new'] ?? 0,
        thisWeekReviewed: json['this_week_reviewed'] ?? 0,
      );
}
