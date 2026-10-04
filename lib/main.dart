import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/core/database/database_helper.dart';
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';
import 'package:my_lucky_lotto_pred/features/authentication/data/user_repository_impl.dart';
import 'package:my_lucky_lotto_pred/features/authentication/presentation/login_page.dart';
import 'package:my_lucky_lotto_pred/features/authentication/presentation/register_page.dart';

import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/data/lotto_type_repository_impl.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/data/lotto_result_repository_impl.dart';

import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/data/lucky_pick_repository_impl.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';

import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_repository.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/data/synchronization_repository_impl.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';

import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_repository.dart';
import 'package:my_lucky_lotto_pred/features/predictions/data/prediction_repository_impl.dart';

import 'package:my_lucky_lotto_pred/features/notifications/domain/notification_repository.dart';
import 'package:my_lucky_lotto_pred/features/notifications/data/notification_repository_impl.dart';

import 'package:my_lucky_lotto_pred/features/settings/domain/audit_repository.dart';
import 'package:my_lucky_lotto_pred/features/settings/data/audit_repository_impl.dart';

import 'package:my_lucky_lotto_pred/features/dashboard/client_dashboard.dart';
import 'package:my_lucky_lotto_pred/features/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.instance.database;

  runApp(LLISApp(db: db));
}

class LLISApp extends StatefulWidget {
  final DatabaseExecutor db;

  const LLISApp({super.key, required this.db});

  @override
  State<LLISApp> createState() => _LLISAppState();
}

class _LLISAppState extends State<LLISApp> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    final userRepo = UserRepositoryImpl(widget.db);
    final lottoTypeRepo = LottoTypeRepositoryImpl(widget.db);
    final lottoResultRepo = LottoResultRepositoryImpl(widget.db);
    final luckyPickRepo = LuckyPickRepositoryImpl(widget.db);
    final luckyPickService = LuckyPickService();
    final syncRepo = SynchronizationRepositoryImpl(widget.db);
    final predRepo = PredictionRepositoryImpl(widget.db);
    final notifRepo = NotificationRepositoryImpl(widget.db);
    final auditRepo = AuditRepositoryImpl(widget.db);

    final syncService = SynchronizationService(
      typeRepo: lottoTypeRepo,
      resultRepo: lottoResultRepo,
      pickRepo: luckyPickRepo,
      pickService: luckyPickService,
      syncRepo: syncRepo,
      notifRepo: notifRepo,
    );

    return MultiProvider(
      providers: [
        Provider<DatabaseExecutor>.value(value: widget.db),
        Provider<UserRepository>.value(value: userRepo),
        Provider<LottoTypeRepository>.value(value: lottoTypeRepo),
        Provider<LottoResultRepository>.value(value: lottoResultRepo),
        Provider<LuckyPickRepository>.value(value: luckyPickRepo),
        Provider<LuckyPickService>.value(value: luckyPickService),
        Provider<SynchronizationRepository>.value(value: syncRepo),
        Provider<SynchronizationService>.value(value: syncService),
        Provider<PredictionRepository>.value(value: predRepo),
        Provider<NotificationRepository>.value(value: notifRepo),
        Provider<AuditRepository>.value(value: auditRepo),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService(userRepo)),
      ],
      child: MaterialApp(
        title: 'Lucky Lotto Information System (LLIS)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated) {
              if (_showRegister) {
                return RegisterPage(onNavigateToLogin: () => setState(() => _showRegister = false));
              } else {
                return LoginPage(onNavigateToRegister: () => setState(() => _showRegister = true));
              }
            }

            if (auth.isAdmin) {
              return const AdminDashboard();
            } else {
              return const ClientDashboard();
            }
          },
        ),
      ),
    );
  }
}
