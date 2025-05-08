import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 2)
class Product extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String createdBy;

  Product({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl = '',
    required this.createdBy,
  });
}