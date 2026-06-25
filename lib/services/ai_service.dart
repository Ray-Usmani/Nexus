import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AiInsightResponse {
  final String summary;
  final List<String> recommendations;

  AiInsightResponse({required this.summary, required this.recommendations});

  factory AiInsightResponse.fromJson(Map<String, dynamic> json) => AiInsightResponse(
        summary: json['summary'] as String? ?? '',
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class VoiceParseResult {
  final String transcription;
  final double? amount;
  final String? categoryId;
  final String? categoryName;
  final String note;
  final String paymentMethod;
  final DateTime? date;
  final List<String> tagIds;
  final String? error;

  VoiceParseResult({
    required this.transcription,
    this.amount,
    this.categoryId,
    this.categoryName,
    this.note = '',
    this.paymentMethod = 'Cash',
    this.date,
    this.tagIds = const [],
    this.error,
  });

  bool get hasAmount => amount != null && amount! > 0;

  factory VoiceParseResult.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr = json['date'] as String?;
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }
    return VoiceParseResult(
      transcription: json['transcription'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      note: json['note'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      date: parsedDate,
      tagIds: (json['tag_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      error: json['error'] as String?,
    );
  }
}

class AiService {
  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (ApiConfig.appSecret.isNotEmpty) {
      h['Authorization'] = 'Bearer ${ApiConfig.appSecret}';
    }
    return h;
  }

  Future<AiInsightResponse?> fetchDailyInsight(Map<String, dynamic> context) =>
      _post('/insights/daily', context);

  Future<AiInsightResponse?> fetchWeeklyInsight(Map<String, dynamic> context) =>
      _post('/insights/weekly', context);

  Future<AiInsightResponse?> sendChat(String message, Map<String, dynamic> context) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/insights/chat'),
        headers: _headers,
        body: jsonEncode({'message': message, 'context': context}),
      );
      if (res.statusCode == 200) {
        return AiInsightResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Send recorded audio (or typed text) to backend for STT + field extraction.
  Future<VoiceParseResult?> parseVoiceExpense({
    required Map<String, dynamic> context,
    List<int>? audioBytes,
    String? audioFilename,
    String? text,
  }) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/voice/parse'),
      );
      if (ApiConfig.appSecret.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer ${ApiConfig.appSecret}';
      }
      req.fields['context'] = jsonEncode(context);
      if (text != null && text.trim().isNotEmpty) {
        req.fields['text'] = text.trim();
      }
      if (audioBytes != null && audioBytes.isNotEmpty) {
        req.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: audioFilename ?? 'recording.m4a',
        ));
      }
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return VoiceParseResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<AiInsightResponse?> _post(String path, Map<String, dynamic> context) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(context),
      );
      if (res.statusCode == 200) {
        return AiInsightResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Local fallback when backend is unavailable.
  AiInsightResponse localFallback(Map<String, dynamic> context) {
    final safe = (context['safeToSpendPerDay'] as num?)?.toDouble() ?? 0;
    final monthDaily = (context['monthDailyTotal'] as num?)?.toDouble() ?? 0;
    final plannedDaily = (context['totalPlannedDaily'] as num?)?.toDouble() ?? 0;
    final envelopes = context['envelopes'] as List<dynamic>? ?? [];

    final over = envelopes.where((e) {
      final m = e as Map<String, dynamic>;
      final p = (m['planned'] as num?)?.toDouble() ?? 0;
      final a = (m['actual'] as num?)?.toDouble() ?? 0;
      return p > 0 && a > p;
    }).toList();

    final recs = <String>[];
    if (safe < 0) {
      recs.add('Daily budget is exceeded — consider pausing discretionary spend.');
    } else if (safe > 0) {
      recs.add('You can safely spend about Rs.${safe.toStringAsFixed(0)} per day for the rest of the month.');
    }
    if (over.isNotEmpty) {
      final names = over.map((e) => (e as Map)['category']).join(', ');
      recs.add('Over budget in: $names');
    }
    if (plannedDaily > 0 && monthDaily / plannedDaily > 0.85) {
      recs.add('You have used most of your daily budget — review Food and Transport.');
    }
    if (recs.isEmpty) {
      recs.add('Spending looks on track. Keep logging daily expenses.');
    }

    return AiInsightResponse(
      summary: 'Local insight: ${recs.first}',
      recommendations: recs,
    );
  }
}
