import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(const ProviderScope(child: CampusConnectApp()));
}

class CampusConnectApp extends ConsumerWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return Consumer(
      builder: (context, ref, child) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            title: 'CampusConnect',
            theme: AppTheme.lightTheme,
            routerConfig: goRouter,
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
      },
    );
  }
}
