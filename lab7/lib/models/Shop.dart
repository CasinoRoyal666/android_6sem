import 'dart:convert';

class Shop {
  int? id;
  String name;
  String address;
  double rating;
  String category;

  Shop({
    this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'category': category,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      rating: map['rating'],
      category: map['category'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Shop.fromJson(String source) => Shop.fromMap(json.decode(source));
}