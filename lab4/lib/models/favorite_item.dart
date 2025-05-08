import 'package:hive/hive.dart';

part 'favorite_item.g.dart';

@HiveType(typeId: 1)
class FavoriteItem extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String data;

  @HiveField(3)
  final DateTime dateAdded;

  FavoriteItem({
    required this.userId,
    required this.title,
    required this.data,
    required this.dateAdded,
  });
}