import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:k2_connect_flutter/k2_connect_flutter.dart';
import 'package:path_provider/path_provider.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  // Add cross-flavor configuration here

  // Initializes the HydratedBloc storage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  await K2ConnectFlutter.initialize(
    baseUrl: 'sandbox.kopokopo.com',
    credentials: K2ConnectCredentials(
      clientId: 'JwKnGgeEhbvn9RD3kwSCwLlvW2BYswsXVhRy3c7uP_k',

      clientSecret: 'S1m9j1qMjbaF0SxE_7e6FEi7DG73MV962MzNMsATQjw',

      apiKey: 'BscG45RXEsLGqurYFqAONvD_7zCY2gRKwNaA3OzADlM',
    ),
    loggingEnabled: true,
  );

  // await K2ConnectFlutter.initialize(
  //   baseUrl: 'sandbox.kopokopo.com',
  //   credentials: K2ConnectCredentials(
  //     clientId: const String.fromEnvironment(
  //       'JwKnGgeEhbvn9RD3kwSCwLlvW2BYswsXVhRy3c7uP_k',
  //     ),
  //     clientSecret: const String.fromEnvironment(
  //       'S1m9j1qMjbaF0SxE_7e6FEi7DG73MV962MzNMsATQjw',
  //     ),
  //     apiKey: const String.fromEnvironment(
  //       'BscG45RXEsLGqurYFqAONvD_7zCY2gRKwNaA3OzADlM',
  //     ),
  //   ),
  //   loggingEnabled: true,
  // );

  runApp(await builder());
}
