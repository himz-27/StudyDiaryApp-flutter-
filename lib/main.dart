import 'dart:async';

import 'package:flutter/material.dart';

import 'mainscreen.dart';
import 'splashscreen.dart';

// Starts the app and switches from the splash screen to the main screen.
void main() {
  runApp(const StudyDiaryApp());
}

class StudyDiaryApp extends StatefulWidget {
  const StudyDiaryApp({super.key});

  @override
  State<StudyDiaryApp> createState() => _StudyDiaryAppState();
}
