import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../state/app_state.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _appGroupId = 'group.budget_tracker';
  static const _androidWidget = 'ExpenseWidgetProvider';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
        await HomeWidget.registerInteractivityCallback(_backgroundCallback);
      }
      _initialized = true;
    } catch (e, stack) {
      debugPrint('WidgetService init failed: $e');
      debugPrint('$stack');
    }
  }

  Future<void> syncFromAppState(AppState state) async {
    if (!_initialized) return;
    try {
      await HomeWidget.saveWidgetData('today_total', state.todayTotal);
      await HomeWidget.saveWidgetData('safe_to_spend', state.safeToSpendPerDay.clamp(0, double.infinity));
      await HomeWidget.updateWidget(
        name: _androidWidget,
        androidName: _androidWidget,
      );
    } catch (e, stack) {
      debugPrint('Widget sync failed: $e');
      debugPrint('$stack');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri?.host == 'add') {
      await HomeWidget.saveWidgetData('open_add', true);
    }
  }
}
