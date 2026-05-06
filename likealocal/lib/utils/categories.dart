class Categories {
  static const cafe = 'Cafe';
  static const food = 'Food';
  static const restaurant = 'Restaurant';
  static const park = 'Park';
  static const museum = 'Museum';
  static const bar = 'Bar';
  static const shop = 'Shop';
  static const other = 'Other';

  static const List<String> all = [
    cafe,
    food,
    restaurant,
    park,
    museum,
    bar,
    shop,
    other,
  ];

  static const Set<String> foodCategories = {
    food,
    restaurant,
    cafe,
  };

  static bool isFoodCategory(String? category) {
    if (category == null) return false;
    return foodCategories.contains(category);
  }
}
