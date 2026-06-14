import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'state/ai_state.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'screens/root_shell.dart';
import 'screens/add_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  try {
    await WidgetService.instance.init();
  } catch (_) {}
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..init()),
        ChangeNotifierProvider(create: (_) => AiState()),
      ],
      child: MaterialApp(
        title: 'Nexus',
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

class _AppRootState extends State<_AppRoot> {
  AppState? _appState;
  final _alertedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onReady());
  }

  Future<void> _onReady() async {
    if (!mounted) return;
    _appState = context.read<AppState>();
    final aiState = context.read<AiState>();
    _appState!.addListener(_sync);
    await aiState.refreshDailyInsight(_appState!);
    _checkOverspend(_appState!);
  }

  void _sync() {
    if (!mounted || _appState == null) return;
    WidgetService.instance.syncFromAppState(_appState!);
    _checkOverspend(_appState!);
  }

  void _checkOverspend(AppState state) {
    for (final e in state.envelopes) {
      final name = e.category?.name ?? 'Category';
      if (e.planned > 0 && e.actual > e.planned && !_alertedCategories.contains(name)) {
        _alertedCategories.add(name);
        NotificationService.instance.showOverspendAlert(name);
      }
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator(color: AppColors.lime)),
      );
    }

    return const RootShell();
  }
}
