import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nganya_split/home/home.dart';
import 'package:nganya_split/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailyReportCubit(),
      child: MaterialApp(
        theme: ThemeData(
          // appBarTheme: AppBarTheme(
          //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // ),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(),
      ),
    );
  }
}
