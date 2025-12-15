import 'package:flutter/material.dart';

import './SplashScreen/splash_screen.dart';
import '../Menu/menu.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => SplashScreen(),
  '/menu': (context) => Menu(),
};