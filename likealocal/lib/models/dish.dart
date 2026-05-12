class Dish {
  final String name;
  final String? description;
  final String? authorId;
  final int upvotes;

  Dish({
    required this.name,
    this.description,
    this.authorId,
    this.upvotes = 0,
  });

  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      name: map['name'] ?? '',
      description: map['description'],
      authorId: map['authorId'],
      upvotes: (map['upvotes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (authorId != null) 'authorId': authorId,
      'upvotes': upvotes,
    };
  }
}
