import 'package:flutter/material.dart';

const brandBlue = Color(0xFF0B4F8A);
const brandAmber = Color(0xFFF59E0B);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brandBlue, secondary: brandAmber),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
