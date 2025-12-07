import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';
import './Menu/menu.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fviaurufxvlqgqnpgsgr.supabase.co',
    anonKey: 'sb_publishable_EscROYQx0JhvwYV04VD8cg_NqjJvuAc',
  );
  runApp(const MyApp()
  );
}

final supabase = Supabase.instance.client;
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: appRoutes,
      // home: Menu(), 
    );
  }
}