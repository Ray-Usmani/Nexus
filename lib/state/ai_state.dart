import 'package:flutter/foundation.dart';

import '../services/ai_service.dart';
import 'app_state.dart';

class AiState extends ChangeNotifier {
  final _service = AiService();

  bool _loading = false;
  String? _dailyInsight;
  String? _weeklySummary;
  List<String> _recommendations = [];
  String? _error;

  bool get loading => _loading;
  String? get dailyInsight => _dailyInsight;
  String? get weeklySummary => _weeklySummary;
  List<String> get recommendations => _recommendations;
  String? get error => _error;

  Future<void> refreshDailyInsight(AppState appState) async {
    await _fetch(appState, daily: true);
  }

  Future<void> refreshWeeklyInsight(AppState appState) async {
    await _fetch(appState, daily: false);
  }

  Future<void> _fetch(AppState appState, {required bool daily}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final context = appState.buildAiContext();
      AiInsightResponse? response;
      if (daily) {
        response = await _service.fetchDailyInsight(context);
      } else {
        response = await _service.fetchWeeklyInsight(context);
      }
      response ??= _service.localFallback(context);

      if (daily) {
        _dailyInsight = response.summary;
      } else {
        _weeklySummary = response.summary;
      }
      _recommendations = response.recommendations;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
