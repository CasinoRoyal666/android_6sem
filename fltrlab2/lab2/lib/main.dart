import 'package:flutter/material.dart';

// Интерфейс
abstract class ShopItem {
  void displayInfo();
  String getDetails();
}

// Абстрактный класс Product
abstract class Product implements ShopItem {
  String _name;
  double _price;

  String get name => _name;
  double get price => _price;

  //валидация
  set price(double newPrice) {
    if (newPrice <= 0) {
      throw ArgumentError('Цена должна быть положительной');
    }
    _price = newPrice;
  }

  Product(this._name, this._price) {
    if (_price <= 0) {
      throw ArgumentError('Цена должна быть положительной');
    }
  }

  @override
  String getDetails() => "Name: $name\nPrice: \$${price.toStringAsFixed(2)}";

  static String shopName = "SuperShop";
  static String getShopInfo() => "Welcome to $shopName!";
}

// Конкретные классы
class Electronics extends Product {
  final String brand;

  // Именованный конструктор
  Electronics(String name, double price, this.brand) : super(name, price);

  @override
  void displayInfo() => print("Electronics: $name ($brand) - \$$price");

  @override
  String getDetails() => "${super.getDetails()}\nBrand: $brand";
}

class Clothing extends Product {
  final String size;

  // Именованный конструктор
  Clothing(String name, double price, this.size) : super(name, price);

  @override
  void displayInfo() => print("Clothing: $name ($size) - \$$price");

  @override
  String getDetails() => "${super.getDetails()}\nSize: $size";
}

void main() {
  var testProduct = Electronics("Test Phone", 100.0, "Test Brand");

  print("Имя продукта: ${testProduct.name}");
  print("Цена продукта: \${testProduct.price}");

  testProduct.displayInfo();
  print(testProduct.getDetails());


  runApp(ShopApp());
}

class ShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Product.shopName,
      home: ShopScreen(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  //msf
  final List<Product> products = [
    Electronics("Smartphone", 599.99, "Samsung"),
    Clothing("T-Shirt", 29.99, "M"),
    Electronics("Laptop", 1299.99, "Apple"),
    Clothing("Jeans", 59.99, "L"),
  ];

  // Метод для применения скидки
  void _applyDiscount(Product product) {
    setState(() {
      product.price *= 0.9; // 10% скидка
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Product.getShopInfo()),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onDiscount: () => _applyDiscount(products[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.error),
        onPressed: () => _showErrorDemo(),
      ),
    );
  }

  void _showErrorDemo() {
    try {
      final testProduct = Clothing("Test", -10, "M");
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Ошибка!"),
          content: Text("Некорректная цена: ${e.toString()}"),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("OK"))],
        ),
      );
    }
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDiscount;

  ProductCard({required this.product, required this.onDiscount});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(product.getDetails()),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  child: Text("-10%"),
                  onPressed: onDiscount,
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () => product.displayInfo(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

//множество
Set<String> uniqueBrands = {'Samsung', 'Apple', 'Nike'};

void exampleFunction({required String message, int times = 1}) {
  for (int i = 0; i < times; i++) {
    print(message);
  }
}

void printProductInfo(Product product, [String? additionalInfo]) {
  print(product.getDetails());
  if (additionalInfo != null) {
    print("Дополнительная информация: $additionalInfo");
  }
}

// Функция с параметром-функцией (callback)
void processProduct(Product product, Function(Product) processor) {
  print("Обработка начата");
  processor(product);
  print("Обработка завершена");
}

void processProducts(List<Product> products) {
  for (var product in products) {
    if (product.price < 50) continue;
    print("Обрабатывается: ${product.name}");
    if (product.price > 1000) break;
  }
}

// Пример использования всех типов функций
void example() {
  var product = Electronics("Phone", 599.99, "Samsung");

  // Использование функции с именованным параметром
  exampleFunction(message: "Тест", times: 2);

  // Использование функции с необязательным параметром
  printProductInfo(product); // без дополнительной информации
  printProductInfo(product, "Специальное предложение"); // с доп. информацией

  // Использование функции с параметром-функцией
  processProduct(product, (p) => print(p.name));
}