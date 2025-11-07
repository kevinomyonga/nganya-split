import 'package:flutter/material.dart';
import 'package:nganya_split/app/app.dart';
import 'package:nganya_split/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await bootstrap(() => const App());
}
