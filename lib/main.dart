import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:carb_counter/meals_list.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log(await getDatabasesPath());
  final database = await openDatabase(join(await getDatabasesPath(), "database.db"),
    version: 2,
    onCreate: (db, version) {
      db.execute("CREATE TABLE meals (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)");
      db.execute("CREATE TABLE foods (id INTEGER PRIMARY KEY AUTOINCREMENT, food_name TEXT, tag_name TEXT, carbs INTEGER, mealid INTEGER, FOREIGN KEY (mealid) REFERENCES meals(id))");
    }
  );
  final cameras = await availableCameras();
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back) {
      runApp(MaterialApp(theme: ThemeData.dark(), title: "Healthy Choices", home: MealsList(camera: camera, database: database)));
      break;
    }
  }
}
