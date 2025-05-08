import 'package:flutter/material.dart';
import '../database/databaseHelper.dart';
import '../models/Shop.dart';

class ShopEditScreen extends StatefulWidget {
  final Shop? shop;

  const ShopEditScreen({Key? key, this.shop}) : super(key: key);

  @override
  _ShopEditScreenState createState() => _ShopEditScreenState();
}

class _ShopEditScreenState extends State<ShopEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ratingController = TextEditingController();
  final _categoryController = TextEditingController();

  bool get isEditing => widget.shop != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _nameController.text = widget.shop!.name;
      _addressController.text = widget.shop!.address;
      _ratingController.text = widget.shop!.rating.toString();
      _categoryController.text = widget.shop!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ratingController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> saveShop() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      final shop = Shop(
        id: isEditing ? widget.shop!.id : null,
        name: _nameController.text,
        address: _addressController.text,
        rating: double.parse(_ratingController.text),
        category: _categoryController.text,
      );

      if (isEditing) {
        await DatabaseHelper.instance.updateShop(shop);
      } else {
        await DatabaseHelper.instance.insertShop(shop);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать магазин' : 'Добавить магазин'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Адрес',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите адрес';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: InputDecoration(
                  labelText: 'Рейтинг',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите рейтинг';
                  }
                  try {
                    final rating = double.parse(value);
                    if (rating < 0 || rating > 5) {
                      return 'Рейтинг должен быть от 0 до 5';
                    }
                  } catch (e) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите категорию';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: saveShop,
                child: Text(
                  isEditing ? 'Сохранить изменения' : 'Добавить магазин',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}