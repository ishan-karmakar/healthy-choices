import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:carb_counter/animated_list.dart';
import 'package:carb_counter/food_item.dart';
import 'package:carb_counter/foods_list.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class MealsList extends StatefulWidget {
  const MealsList({super.key, required this.camera, required this.database});
  final CameraDescription camera;
  final Database database;

  @override
  createState() => _MealsListState();
}

class _MealsListState extends State<MealsList> {
  final mealsList = CustomAnimatedList<Meal>();
  String mealName = "";
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var item in (await widget.database.query("meals")).map((e) => Meal.fromMap(widget.camera, widget.database, e)).toList()) {
        mealsList.insert(item);
      }
      final TooltipState tooltip = _key.currentState as TooltipState;
      if (mealsList.length == 0) {
        tooltip.ensureTooltipVisible();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Healthy Choices")),
      body: mealsList,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (innerContext) => AlertDialog(
              title: const Text("Meal Name"),
              content: TextField(
                onChanged: (value) => mealName = value,
              ),
              actions: [
                MaterialButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  child: const Text("OK"),
                  onPressed: () {
                    if (mealName == "") {
                      Navigator.pop(context);
                      return;
                    }
                    for (var meal in mealsList.list) {
                      if (meal.title == mealName) {
                        showDialog(
                          context: innerContext,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text("Invalid Name"),
                            content: const Text("The meal already exists"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                            ],
                          )
                        );
                        return;
                      }
                    }
                    final meal = Meal(title: mealName, camera: widget.camera, db: widget.database);
                    meal.insert().then((id) {
                      meal.id = id;
                      mealsList.insert(meal);
                      mealName = "";
                      Navigator.pop(innerContext);
                    });
                  },
                )
              ],
            )
          );
        },
        child: Tooltip(
          key: _key,
          message: "Create your first meal!",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class Meal {
  Meal({required this.title, required this.camera, required this.db, this.id});
  final CameraDescription camera;
  int? id;
  final String title;
  final String? subtitle = null;
  final Database db;
  List<FoodItem>? foods;

  Map<String, dynamic> toMap() => { "name": title };
  factory Meal.fromMap(CameraDescription camera, Database db, Map<String, Object?> map) => Meal(title: map["name"]!.toString(), id: map["id"] as int, camera: camera, db: db);
  Future<int> insert() => db.insert("meals", toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> dispose() => db.delete("meals", where: "id = ?", whereArgs: [id]);

  void onTap(BuildContext context) async {
    foods = await Navigator.push(context, MaterialPageRoute(builder: (context) => FoodMenu(meal: this, camera: camera, db: db, initialItems: foods)));
    log(foods.toString());
  }
}