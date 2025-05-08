import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

// Mixins
mixin DiscountProcessor {
  double calculateDiscount(double price, double discountPercent) {
    return price * (1 - discountPercent / 100);
  }
}

mixin PriceFormatter {
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
}

// Интерфейс для товаров
abstract class ShopItem {
  void displayInfo();
  String getDetails();
}

// Абстрактный класс Product
abstract class Product implements ShopItem, Comparable<Product> {
  String _name;
  double _price;

  String get name => _name;
  double get price => _price;

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

  @override
  int compareTo(Product other) {
    return _price.compareTo(other._price);
  }

  static String shopName = "SuperShop";
  static String getShopInfo() => "Welcome to $shopName!";

  Map<String, dynamic> toJson();
}

// Конкретные классы
class Electronics extends Product with DiscountProcessor, PriceFormatter {
  final String brand;

  Electronics(String name, double price, this.brand) : super(name, price);

  @override
  void displayInfo() => print("Electronics: $name ($brand) - ${formatPrice(price)}");

  @override
  String getDetails() => "${super.getDetails()}\nBrand: $brand";

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': _name,
      'price': _price,
      'brand': brand,
      'type': 'electronics'
    };
  }

  factory Electronics.fromJson(Map<String, dynamic> json) {
    return Electronics(
      json['name'] as String,
      json['price'] as double,
      json['brand'] as String,
    );
  }
}

class Clothing extends Product with DiscountProcessor, PriceFormatter {
  final String size;

  Clothing(String name, double price, this.size) : super(name, price);

  @override
  void displayInfo() => print("Clothing: $name ($size) - ${formatPrice(price)}");

  @override
  String getDetails() => "${super.getDetails()}\nSize: $size";

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': _name,
      'price': _price,
      'size': size,
      'type': 'clothing'
    };
  }

  factory Clothing.fromJson(Map<String, dynamic> json) {
    return Clothing(
      json['name'] as String,
      json['price'] as double,
      json['size'] as String,
    );
  }
}
class ProductIterator implements Iterator<Product> {
  final List<Product> _products;
  int _currentIndex = -1;

  ProductIterator(this._products);

  @override
  Product get current {
    if (_currentIndex < 0 || _currentIndex >= _products.length) {
      throw StateError("No current element");
    }
    return _products[_currentIndex];
  }

  @override
  bool moveNext() {
    _currentIndex++;
    return _currentIndex < _products.length;
  }
}
class ProductCollection implements Iterable<Product> {
  final List<Product> _products;

  ProductCollection(this._products);

  @override
  Iterator<Product> get iterator => ProductIterator(_products);

  @override
  bool any(bool Function(Product) test) => _products.any(test);

  @override
  List<Product> toList({bool growable = true}) => _products.toList(growable: growable);

  @override
  Iterable<T> map<T>(T Function(Product) f) => _products.map(f);

  @override
  Iterable<R> cast<R>() => _products.cast<R>();

  @override
  bool contains(Object? element) => _products.contains(element);

  @override
  Product elementAt(int index) => _products.elementAt(index);

  @override
  bool every(bool Function(Product) test) => _products.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(Product) f) => _products.expand(f);

  @override
  Product get first => _products.first;

  @override
  Product firstWhere(bool Function(Product) test, {Product Function()? orElse}) =>
      _products.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T, Product) combine) =>
      _products.fold(initialValue, combine);

  @override
  Iterable<Product> followedBy(Iterable<Product> other) => _products.followedBy(other);

  @override
  void forEach(void Function(Product) action) => _products.forEach(action);

  @override
  bool get isEmpty => _products.isEmpty;

  @override
  bool get isNotEmpty => _products.isNotEmpty;

  @override
  String join([String separator = ""]) => _products.join(separator);

  @override
  Product get last => _products.last;

  @override
  Product lastWhere(bool Function(Product) test, {Product Function()? orElse}) =>
      _products.lastWhere(test, orElse: orElse);

  @override
  int get length => _products.length;

  @override
  Product reduce(Product Function(Product, Product) combine) => _products.reduce(combine);

  @override
  Product singleWhere(bool Function(Product) test, {Product Function()? orElse}) =>
      _products.singleWhere(test, orElse: orElse);

  @override
  Iterable<Product> skip(int count) => _products.skip(count);

  @override
  Iterable<Product> skipWhile(bool Function(Product) test) => _products.skipWhile(test);

  @override
  Iterable<Product> take(int count) => _products.take(count);

  @override
  Iterable<Product> takeWhile(bool Function(Product) test) => _products.takeWhile(test);

  @override
  Iterable<Product> where(bool Function(Product) test) => _products.where(test);

  @override
  Iterable<T> whereType<T>() => _products.whereType<T>();

  @override
  Set<Product> toSet() => _products.toSet();

  @override
  Product get single {
    if (_products.length != 1) {
      throw StateError('Collection does not contain exactly one element');
    }
    return _products.first;
  }
}

// Сервис для работы с асинхронными операциями
class ProductService {
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(Duration(seconds: 2));
    return [
      Electronics("Smartphone", 599.99, "Samsung"),
      Clothing("T-Shirt", 29.99, "M"),
    ];
  }

  Future<void> saveProduct(Product product) async {
    await Future.delayed(Duration(seconds: 1));
    print('Product ${product.name} saved');
    print('JSON: ${jsonEncode(product.toJson())}');
  }
}

// Класс для работы со стримами
class ProductStream {
  // Single subscription stream
  Stream<Product> getProductStream() async* {
    final products = [
      Electronics("Phone", 599.99, "Samsung"),
      Clothing("Shirt", 29.99, "M"),
    ];

    for (var product in products) {
      await Future.delayed(Duration(seconds: 1));
      yield product;
    }
  }

  // Broadcast stream
  final _controller = StreamController<Product>.broadcast();

  Stream<Product> get productUpdates => _controller.stream;

  void addProduct(Product product) {
    _controller.sink.add(product);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  var products = [
    Electronics("Phone", 599.99, "Xiaomi"),
    Clothing("T-Shirt", 29.99, "M"),
    Electronics("Laptop", 1299.99, "Huawei"),
  ];

  products.sort();
  print("Сортировка продуктов по цене:");
  for (var product in products) {
    print("${product.name}: ${product.price}");
  }

  var productCollection = ProductCollection(products);
  print("\nПеребор продуктов через Iterable:");
  for (var product in productCollection) {
    print("${product.name}: ${product.price}");
  }

  var iterator = productCollection.iterator;
  while (iterator.moveNext()) {
    print("Итератор: ${iterator.current.name} - \${iterator.current.price}");
  }
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
  final ProductService _productService = ProductService();
  final ProductStream _productStream = ProductStream();
  late Future<List<Product>> _productsFuture;
  List<Product> products = [];
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.fetchProducts();
    _setupProductStream();
    _setupBroadcastStream();
  }

  void _setupProductStream() {
    _streamSubscription = _productStream.getProductStream().listen(
          (product) {
        print('Получен продукт из Single Stream: ${product.name}');
      },
    );
  }

  void _setupBroadcastStream() {
    _productStream.productUpdates.listen(
          (product) {
        setState(() {
          products.add(product);
        });
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _productStream.dispose();
    super.dispose();
  }

  void _applyDiscount(Product product) {
    if (product is Electronics) {
      setState(() {
        product.price = product.calculateDiscount(product.price, 10);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Product.getShopInfo()),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No products available'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) => ProductCard(
              product: products[index],
              onDiscount: () => _applyDiscount(products[index]),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              final newProduct = Electronics("New Phone", 799.99, "Apple");
              _productStream.addProduct(newProduct);
              _productService.saveProduct(newProduct);
            },
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            child: Icon(Icons.error),
            onPressed: _showErrorDemo,
          ),
        ],
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