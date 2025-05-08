import 'package:flutter/material.dart';

class AppTheme {
  // Приватный конструктор, чтобы запретить создание экземпляров класса
  AppTheme._();

  // Светлая тема приложения
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    fontFamily: 'Arial',
  );
}