import 'package:hive/hive.dart';

part 'user.g.dart'; // Связь с сгенерированным кодом

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String role;

  User({required this.username, required this.role});
}