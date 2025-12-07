import 'package:flutter/material.dart';

import './SplashScreen/splash_screen.dart';
// import './Autentikasi/autentikasi.dart';
// import 'Login/login.dart';
// import 'Register/register.dart';
// import 'LupaPassword/lupa_password.dart';
import '../Menu/menu.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => SplashScreen(),
  // '/auth': (context) => Autentikasi(),
  // '/form-login': (context) => Masuk(),
  // '/form-register': (context) => Daftar(),
  // '/form-lupa-password': (context) => LupaPassword(),

  '/menu': (context) => Menu(),
};