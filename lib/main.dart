import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';
import 'state/app_state.dart';
import 'state/accounts_state.dart';
import 'state/ai_state.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'screens/root_shell.dart';
import 'screens/add_expense_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (e, stack) {
    debugPrint('Notification init failed: $e');
    debugPrint('$stack');
  }
  try {
    await WidgetService.instance.init();
  } catch (e, stack) {
    debugPrint('Widget init failed: $e');
    debugPrint('$stack');
  }
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AccountsState()),
        ChangeNotifierProvider(create: (_) => AiState()),
      ],
      child: MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AppRoot(),
        onGenerateRoute: (settings) {
          if (settings.name == '/add') {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: AddExpenseScreen()));
          }
          return null;
        },
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  AppState? _appState;
  final _alertedCategories = <String>{};
  bool _needsUnlock = false;
  /// Set after a successful unlock so we ignore the [resumed] event from
  /// dismissing the system biometric sheet (otherwise the app re-locks).
  bool _skipNextResumeLock = false;
  /// Set when the app goes to background while unlocked; cleared after re-lock.
  bool _lockOnNextResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onReady());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState?.removeListener(_sync);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_appState?.biometricsEnabled != true) return;

    if (state == AppLifecycleState.paused && !_needsUnlock) {
      _lockOnNextResume = true;
    } else if (state == AppLifecycleState.resumed && mounted) {
      if (_skipNextResumeLock) {
        _skipNextResumeLock = false;
        return;
      }
      if (_lockOnNextResume) {
        _lockOnNextResume = false;
        setState(() => _needsUnlock = true);
      }
    }
  }

  Future<void> _onReady() async {
    if (!mounted) return;
    _appState = context.read<AppState>();
    final aiState = context.read<AiState>();
    final accountsState = context.read<AccountsState>();

    try {
      await Future.wait([
        _appState!.init(),
        accountsState.init(),
      ]);
    } catch (e, stack) {
      debugPrint('AppState init failed: $e');
      debugPrint('$stack');
      return;
    }
    if (!mounted) return;

    await NotificationService.instance.applyPreferences(
      dailyEnabled: _appState!.notificationsDaily,
      weeklyEnabled: _appState!.notificationsWeekly,
    );

    if (_appState!.biometricsEnabled) {
      setState(() => _needsUnlock = true);
    }

    _appState!.addListener(_sync);
    WidgetService.instance.syncFromAppState(_appState!);

    Future.microtask(() async {
      if (!mounted || _appState == null) return;
      try {
        await aiState.refreshDailyInsight(_appState!);
      } catch (e, stack) {
        debugPrint('Daily insight refresh failed: $e');
        debugPrint('$stack');
      }
      if (mounted && _appState != null) {
        _checkOverspend(_appState!);
      }
    });
  }

  void _sync() {
    if (!mounted || _appState == null) return;
    WidgetService.instance.syncFromAppState(_appState!);
    _checkOverspend(_appState!);
  }

  void _checkOverspend(AppState state) {
    if (!state.notificationsOverspend) return;
    for (final e in state.envelopes) {
      final name = e.category?.name ?? 'Category';
      if (e.planned > 0 && e.actual > e.planned && !_alertedCategories.contains(name)) {
        _alertedCategories.add(name);
        NotificationService.instance.showOverspendAlert(name);
      }
    }
  }

  void _onUnlocked() {
    _skipNextResumeLock = true;
    setState(() => _needsUnlock = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 72),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.amber),
            ],
          ),
        ),
      );
    }

    if (state.biometricsEnabled && _needsUnlock) {
      return LockScreen(onUnlocked: _onUnlocked);
    }

    return const RootShell();
  }
}
