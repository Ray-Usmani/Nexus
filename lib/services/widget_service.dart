import 'package:home_widget/home_widget.dart';

import '../state/app_state.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _appGroupId = 'group.budget_tracker';
  static const _androidWidget = 'ExpenseWidgetProvider';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  Future<void> syncFromAppState(AppState state) async {
    await HomeWidget.saveWidgetData('today_total', state.todayTotal);
    await HomeWidget.saveWidgetData('safe_to_spend', state.safeToSpendPerDay.clamp(0, double.infinity));
    await HomeWidget.updateWidget(
      name: _androidWidget,
      androidName: _androidWidget,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri?.host == 'add') {
      await HomeWidget.saveWidgetData('open_add', true);
    }
  }
}
