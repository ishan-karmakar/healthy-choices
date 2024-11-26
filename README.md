# Healthy Choices

Healthy Choices is an app designed to help users make healthier eating choices by providing easy access to nutrition information for common ingredients. This app helps by offering nutritional insights and allowing you to create and store custom meals.

This app was developed as part of the [Congressional App Challenge](https://www.congressionalappchallenge.us/)

# Features
- Nutrition Data: View nutritional information for ingredients, with a focus on carbohydrate content
- Ingredient Input: Easily add ingredients either by typing their names (with autocomplete suggestions) or by using the camera to scan the ingredients
- Meal Creation: Create custom meals by combining ingredients
- Meal Persistence: Save and store your created meals locally for future access

# Implementation
- Nutrition Lookup
  - Nutrition data for ingredients is sourced from [Nutritionix](https://www.nutritionix.com/business/api)
  - Right now, the app displays only carbohydrate information for simplicity, but additional nutrients can be added in future versions
- Ingredient Entry
  - Users can input ingredients either by typing the name of the food item, with an autocomplete feature to speed up the search process
  - Alternatively, users can use the app's camera feature to take a photo of an ingredient. The TensorFlow Lite model detects the food and automatically inputs the ingredient name
- Meal Creation
  - Once you've added ingredients, you can combine them to create a meal
  - The nutritional information for your custom meals is automatically calculated based on the ingredients you've added
- Meal Storage
  - Created meals are saved locally in an SQLite database, so you can revisit your meals and their nutritional content at any time

# Tech Stack
- Frontend: Built with Flutter for cross-platform mobile, app, and web development
- Nutrition Information: Data provided by [Nutritionix](https://www.nutritionix.com/business/api)
- Machine Learning: TensorFlow Lite model used for food detection from camera inputs
- Local Database: SQLite for local meal storage and persistence
