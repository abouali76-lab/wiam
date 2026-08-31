import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'state/parent_state.dart';
import 'state/child_device_state.dart';
import 'theme.dart';
import 'screens/mode_select_screen.dart';

void main() {
  runApp(const WiamApp());
}

class WiamApp extends StatelessWidget {
  const WiamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final parentApi = ApiClient();
    final childApi = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParentAppState(parentApi)..restoreSession()),
        ChangeNotifierProvider(create: (_) => ChildDeviceState(childApi)..restore()),
      ],
      child: MaterialApp(
        title: 'وئام',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: wiamLightTheme(),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const ModeSelectScreen(),
      ),
    );
  }
}
