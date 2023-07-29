import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:sqflite/sqflite.dart';

const Map<String, String> nutritionxHeaders = {
  "x-app-id": "e0bd4eb1",
  "x-app-key": "4bbc8728bc05cb7a33ab424a9635a353"
};

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class FoodItem {
  final String foodName;
  final String tagName;
  final Database db;
  int? id;
  final int mealId;
  late final String displayName;
  late final FoodNutrients nutrients;

  String get title => displayName;
  String? get subtitle => "${nutrients.nfCarbs} Carbs";

  FoodItem({required this.foodName, required this.tagName, required this.db, required this.mealId}) {
    displayName = (' '.allMatches(tagName).length > ' '.allMatches(foodName).length ? tagName : foodName).split(" ").map((w) => w.capitalize()).join(" ");
  }
  factory FoodItem.fromJson(int mealId, Database db, Map<String, dynamic> json) => FoodItem(db: db, mealId: mealId, foodName: json["food_name"], tagName: json["tag_name"]);
  factory FoodItem.fromMap(int mealId, Database db, Map<String, Object?> map) {
    var item = FoodItem(
        db: db,
        mealId: mealId,
        foodName: map["food_name"].toString(),
        tagName: map["tag_name"].toString()
    );
    item.nutrients = FoodNutrients(nfCarbs: map["carbs"]! as int);
    return item;
  }
  Map<String, Object?> toMap() => { "food_name": foodName, "tag_name": tagName, "carbs": nutrients.nfCarbs, "mealid": mealId };

  Future<void> getCarbs() async {
    Map<String, dynamic> body = { "query": foodName };
    final response = await post(Uri.parse("https://trackapi.nutritionix.com/v2/natural/nutrients"), headers: { ...nutritionxHeaders, "Content-Type": "application/json" }, body: jsonEncode(body));
    nutrients = FoodNutrients.fromJson(jsonDecode(response.body));
  }

  void onTap(BuildContext _) {}
  Future<int> insert() => db.insert("foods", toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> dispose() => db.delete("foods", where: "id = ?", whereArgs: [id]);
}

class FoodNutrients {
  final int nfCarbs;
  const FoodNutrients({required this.nfCarbs});
  factory FoodNutrients.fromJson(Map<String, dynamic> json) => FoodNutrients(nfCarbs: int.parse(json["foods"][0]["nf_total_carbohydrate"].toStringAsFixed(0)));
  Map<String, dynamic> toJson() => { "foods": [{ "nf_total_carbohydrate": nfCarbs }] };
}