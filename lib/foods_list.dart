import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:carb_counter/animated_list.dart';
import 'package:carb_counter/meals_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart';
import 'package:sqflite/sqflite.dart';
import 'food_camera.dart';
import 'food_item.dart';

class FoodMenu extends StatefulWidget {
  const FoodMenu({super.key, required this.meal, required this.camera, required this.db, required this.initialItems});
  final CameraDescription camera;
  final Meal meal;
  final Database db;
  final List<FoodItem>? initialItems;

  @override
  createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> {
  final controller = TextEditingController();
  final foodsList = CustomAnimatedList<FoodItem>();

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<FoodItem> foods;
      if (widget.initialItems == null) {
        final sqlFoods = await widget.db.query(
            "foods", columns: ["id", "food_name", "tag_name", "carbs"],
            where: "mealid = ?",
            whereArgs: [widget.meal.id]);
        foods = sqlFoods.map((e) => FoodItem.fromMap(widget.meal.id!, widget.db, e)).toList();
      } else {
        foods = widget.initialItems!;
      }
      for (final food in foods) {
        foodsList.insert(food);
      }
    });
  }

  Future<List<String>> getPredictedFood() async => await Navigator.push(context, MaterialPageRoute(builder: (context) => TakePicture(camera: widget.camera)));

  Future<List<FoodItem>> getFoods(String pattern) async {
    final response = await get(Uri.parse("https://trackapi.nutritionix.com/v2/search/instant?query=$pattern&branded=false&self=false"), headers: nutritionxHeaders);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> items = json["common"];
      final itemsDeDuped = <FoodItem>[];
      for (final item in items) {
        var exists = false;
        for (final item2 in itemsDeDuped) {
          if (item2.tagName == item["tagName"]) {
            exists = true;
            break;
          }
        }
        if (exists) continue;
        itemsDeDuped.add(FoodItem.fromJson(widget.meal.id!, widget.db, item));
      }
      return itemsDeDuped;
    } else {
      throw Exception("Failed to retrieve nutrition information");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.meal.title)),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, foodsList.list);
          return false;
        },
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: "Enter food",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () {
                              getPredictedFood().then((result) {
                                if (result.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                    ..removeCurrentSnackBar()
                                    ..showSnackBar(const SnackBar(content: Text("Couldn't identify food from the image")));
                                } else {
                                  for (final name in result) {
                                    getFoods(name).then((foods) {
                                      if (foods.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                          ..removeCurrentSnackBar()
                                          ..showSnackBar(SnackBar(content: Text("Couldn't get nutrition information for $name")));
                                      } else {
                                        final food = foods.first;
                                        food.getCarbs().then((r) => foodsList.insert(food));
                                      }
                                    });
                                  }
                                }
                              });
                            },
                          )
                      )
                  ),
                  suggestionsCallback: (pattern) async {
                    if (pattern.length <= 2) return [];
                    return await getFoods(pattern);
                  },
                  itemBuilder: (context, v) => ListTile(title: Text(v.displayName)),
                  onSuggestionSelected: (suggestion) async {
                    controller.clear();
                    await suggestion.getCarbs();
                    suggestion.id = await suggestion.insert();
                    foodsList.insert(suggestion);
                  },
                  hideKeyboardOnDrag: true,
                  hideSuggestionsOnKeyboardHide: false,
                )
            ),
            Expanded(child: foodsList)
          ],
        ),
      )
    );
  }
}