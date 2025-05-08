import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'models/user.dart';
import 'models/favorite_item.dart';
import 'models/product.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптеров
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(FavoriteItemAdapter());
  Hive.registerAdapter(ProductAdapter());

  // Открытие боксов
  await Hive.openBox<User>('users');

  // Создание начальных пользователей, если их нет
  var userBox = Hive.box<User>('users');
  if (userBox.isEmpty) {
    userBox.add(User(username: 'admin', role: 'admin'));
    userBox.add(User(username: 'manager', role: 'manager'));
    userBox.add(User(username: 'user', role: 'user'));
  }

  final key = utf8.encode('mySecureKey123'); // Ключ для шифрования
  final encryptionKey = sha256.convert(key).bytes;

  await Hive.openBox<FavoriteItem>(
    'favorites',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  final wrongKey = utf8.encode('wrongKey456');
  final wrongEncryptionKey = sha256.convert(wrongKey).bytes;

  await Hive.openBox<Product>('products');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Arial',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/detail': (context) => const DetailScreen(),
        '/products': (context) => const ProductListScreen(),
        '/products/add': (context) => const ProductEditScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _batteryLevel;
  String? _deviceInfo;
  String _urlToOpen = 'https://flutter.dev';
  File? _image;
  final picker = ImagePicker();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    _getDeviceInfo();
    _currentUser = Hive.box<User>('users').getAt(0);
  }

  // Platform channel for battery level
  static const platform = MethodChannel('samples.flutter.dev/battery');
  static const deviceInfoChannel = MethodChannel('samples.flutter.dev/device_info');
  static const browserChannel = MethodChannel('samples.flutter.dev/browser');

  // Get battery level
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level: $result%';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  // Get device manufacturer (variant 2)
  Future<void> _getDeviceInfo() async {
    String deviceInfo;
    try {
      final String result = await deviceInfoChannel.invokeMethod('getDeviceManufacturer');
      deviceInfo = 'Device Manufacturer: $result';
    } on PlatformException catch (e) {
      deviceInfo = "Failed to get device info: '${e.message}'.";
    }

    setState(() {
      _deviceInfo = deviceInfo;
    });
  }

  // Open URL in browser (variant 3)
  Future<void> _openBrowser() async {
    try {
      await browserChannel.invokeMethod('openUrl', {'url': _urlToOpen});
    } on PlatformException catch (e) {
      print("Failed to open browser: '${e.message}'.");
    }
  }

  // Get image from camera
  Future<void> _getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _addToFavorites(String title, String data) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user selected')),
      );
      return;
    }

    final favoritesBox = Hive.box<FavoriteItem>('favorites');
    final newFavorite = FavoriteItem(
      userId: _currentUser!.username,
      title: title,
      data: data,
      dateAdded: DateTime.now(),
    );

    await favoritesBox.add(newFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to favorites')),
    );
  }

  // Переключение пользователя
  void _switchUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User'),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder(
            valueListenable: Hive.box<User>('users').listenable(),
            builder: (context, Box<User> box, _) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final user = box.getAt(index);
                  return ListTile(
                    title: Text(user?.username ?? 'Unknown'),
                    subtitle: Text('Role: ${user?.role ?? 'Unknown'}'),
                    selected: user?.username == _currentUser?.username,
                    onTap: () {
                      setState(() {
                        _currentUser = user;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _demonstrateWrongKey() async {
    final wrongKey = utf8.encode('wrongKey456');
    final wrongEncryptionKey = sha256.convert(wrongKey).bytes;

    try {
      await Hive.close();

      final wrongBox = await Hive.openBox<FavoriteItem>(
        'favorites',
        encryptionCipher: HiveAesCipher(wrongEncryptionKey),
      );

      try {
        final firstItem = wrongBox.getAt(0);
        print(firstItem.toString());

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Критическая ошибка'),
            content: const Text('ВНИМАНИЕ: Шифрование НЕ работает! Данные доступны без правильного ключа.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (readError) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Тест пройден'),
            content: Text('Ошибка чтения: $readError\nШифрование работает корректно.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (openError) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Тест пройден'),
          content: Text('Ошибка открытия бокса: $openError\nШифрование работает корректно.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {

      await Hive.close();

      final key = utf8.encode('mySecureKey123');
      final encryptionKey = sha256.convert(key).bytes;
      await Hive.openBox<FavoriteItem>(
        'favorites',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }
  }

  void _compressBox() async {
    final favoritesBox = Hive.box<FavoriteItem>('favorites');
    await favoritesBox.compact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Box Compression'),
        content: const Text('Favorites box has been compressed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Welcome, ${_currentUser?.username ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: _switchUser,
            tooltip: 'Switch User',
          ),
          if (_currentUser?.role == 'admin' || _currentUser?.role == 'manager')
            IconButton(
              icon: const Icon(Icons.inventory),
              onPressed: () => Navigator.pushNamed(context, '/products'),
              tooltip: 'Manage Products',
            ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            tooltip: 'Favorites',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Test Wrong Encryption Key'),
                onTap: _demonstrateWrongKey,
              ),
              PopupMenuItem(
                child: const Text('Compress Box'),
                onTap: _compressBox,
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          DashboardScreen(
            batteryLevel: _batteryLevel ?? 'Unknown',
            deviceInfo: _deviceInfo ?? 'Unknown',
            onDetail: (title, data) {
              Navigator.pushNamed(
                context,
                '/detail',
                arguments: DetailArguments(title: title, data: data),
              );
            },
            onGetImage: _getImageFromCamera,
            image: _image,
            currentUser: _currentUser,
            onAddToFavorites: _addToFavorites,
          ),
          LearningHubScreen(
            onOpenBrowser: () => _openBrowser(),
            urlToOpen: _urlToOpen,
            onUrlChanged: (String value) {
              setState(() {
                _urlToOpen = value;
              });
            },
            onDetail: (title, data) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    title: title,
                    data: data,
                  ),
                ),
              );
            },
            onAddToFavorites: _addToFavorites,
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String batteryLevel;
  final String deviceInfo;
  final Function(String, String) onDetail;
  final Function() onGetImage;
  final Function(String, String) onAddToFavorites;
  final File? image;
  final User? currentUser;

  const DashboardScreen({
    super.key,
    required this.batteryLevel,
    required this.deviceInfo,
    required this.onDetail,
    required this.onGetImage,
    required this.onAddToFavorites,
    this.image,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {},
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello ${currentUser?.username ?? 'User'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Role: ${currentUser?.role ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        batteryLevel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        deviceInfo,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard and Camera button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onGetImage,
                          child: const Row(
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(width: 5),
                              Text('Camera'),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Row(
                            children: [
                              Text(
                                'VIEW',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Show camera image if available
                if (image != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (image != null) const SizedBox(height: 10),

                // Отображение продуктов, если пользователь не админ
                if (currentUser?.role == 'user')
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: Hive.box<Product>('products').listenable(),
                      builder: (context, Box<Product> box, _) {
                        if (box.isEmpty) {
                          return const Center(
                            child: Text('No products available'),
                          );
                        }

                        return ListView.builder(
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            final product = box.getAt(index);
                            if (product == null) return const SizedBox();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                  '${product.description}\nPrice: \$${product.price.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {
                                    onAddToFavorites(
                                      product.name,
                                      'Price: \$${product.price.toStringAsFixed(2)}\n${product.description}',
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                // Оригинальный контент для всех пользователей
                if (currentUser?.role != 'user')
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendar row
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onDetail('Calendar', 'Your upcoming events and schedule'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Calendar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Email',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Calendar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () => onDetail('Next Class', 'Foundation of Nursing and Midwifery\nThu 16 March, 11:00AM'),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Next Class',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Thu 16 March, 11:00AM',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Foundation of Nursing and Midwifery',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Add to favorites button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.favorite_border),
                                    onPressed: () {
                                      onAddToFavorites(
                                        'Next Class',
                                        'Foundation of Nursing and Midwifery\nThu 16 March, 11:00AM',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Essentials section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Essentials',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Row(
                                  children: [
                                    Text(
                                      'VIEW',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Essentials grid
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    onDetail('Library', 'Access all your study materials and resources');
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 120,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.search,
                                                  color: Colors.white,
                                                ),
                                                Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Library',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: IconButton(
                                          icon: const Icon(Icons.favorite_border, color: Colors.white),
                                          onPressed: () {
                                            onAddToFavorites(
                                              'Library',
                                              'Access all your study materials and resources',
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 120,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.school,
                                            color: Colors.white,
                                          ),
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'MyUni',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 120,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.book,
                                            color: Colors.white,
                                          ),
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Learning Hub',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 120,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.white,
                                          ),
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Chat',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LearningHubScreen extends StatelessWidget {
  final Function(String, String) onDetail;
  final Function() onOpenBrowser;
  final String urlToOpen;
  final Function(String) onUrlChanged;
  final Function(String, String) onAddToFavorites;

  const LearningHubScreen({
    super.key,
    required this.onDetail,
    required this.onOpenBrowser,
    required this.urlToOpen,
    required this.onUrlChanged,
    required this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Learning Hub',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Open browser section
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Enter URL to open',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: urlToOpen),
                      onChanged: onUrlChanged,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: onOpenBrowser,
                      child: const Text('Open in Browser'),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onDetail('Validate', 'Tools for validating your academic progress and assignments'),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_box),
                                  SizedBox(width: 8),
                                  Text(
                                    'Validate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time),
                                SizedBox(width: 8),
                                Text(
                                  'Activity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward),
                                SizedBox(width: 8),
                                Text(
                                  'Drop-Ins',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list),
                                SizedBox(width: 8),
                                Text(
                                  'My List',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Rest of the content with grey background
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Text(
                              'VIEW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Today activities
                  Row(
                    children: [
                      // Drop-in card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onDetail('Drop-In', 'Student Mentor Study Space - Sport and Exercise Science'),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DROP-IN',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '09:00 AM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildBulletItem('Student'),
                                        _buildBulletItem('Mentor Study'),
                                        _buildBulletItem('Space - Sport and Exercise'),
                                        _buildBulletItem('Science'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {
                                    onAddToFavorites(
                                      'Drop-In',
                                      'Student Mentor Study Space - Sport and Exercise Science at 09:00 AM',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Workshop card - Matching height with Drop-in card
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'WORKSHOP',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '11:00 AM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildBulletItem('Resume Help'),
                                      _buildBulletItem('Drop-In'),
                                      const SizedBox(height: 80),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {
                                  onAddToFavorites(
                                    'Workshop',
                                    'Resume Help Drop-In at 11:00 AM',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // All Activities section
                  const Text(
                    'All Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Workshops and Online items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildExpandableItem('Workshops'),
                          const SizedBox(height: 10),
                          _buildExpandableItem('Online'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableItem(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

// Detail screen for navigated data
class DetailScreen extends StatelessWidget {
  final String? title;
  final String? data;

  const DetailScreen({super.key, this.title, this.data});

  @override
  Widget build(BuildContext context) {
    // If arguments are passed through the routes, extract them
    final args = ModalRoute.of(context)?.settings.arguments as DetailArguments?;
    final displayTitle = title ?? args?.title ?? 'Detail';
    final displayData = data ?? args?.data ?? 'No data available';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              if (Hive.box<User>('users').isNotEmpty) {
                final currentUser = Hive.box<User>('users').getAt(0);
                final favoritesBox = Hive.box<FavoriteItem>('favorites');

                final newFavorite = FavoriteItem(
                  userId: currentUser?.username ?? 'unknown',
                  title: displayTitle,
                  data: displayData,
                  dateAdded: DateTime.now(),
                );

                favoritesBox.add(newFavorite);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to favorites')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayData,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// Экран для списка продуктов (доступен только admin/manager)
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/products/add');
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No products yet. Add some!'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final product = box.getAt(index);
              if (product == null) return const SizedBox();

              return Dismissible(
                key: Key(product.name + index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  box.deleteAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} deleted')),
                  );
                },
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('Price: \$${product.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductEditScreen(
                                product: product,
                                index: index,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          // Получаем текущего пользователя
                          final currentUser = Hive.box<User>('users').getAt(0);

                          if (currentUser != null) {
                            final favoritesBox = Hive.box<FavoriteItem>('favorites');

                            final newFavorite = FavoriteItem(
                              userId: currentUser.username,
                              title: product.name,
                              data: 'Price: \$${product.price.toStringAsFixed(2)}\n${product.description}',
                              dateAdded: DateTime.now(),
                            );

                            favoritesBox.add(newFavorite);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to favorites')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          title: product.name,
                          data: '${product.description}\nPrice: \$${product.price.toStringAsFixed(2)}',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductEditScreen extends StatefulWidget {
  final Product? product;
  final int? index;

  const ProductEditScreen({super.key, this.product, this.index});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final productBox = Hive.box<Product>('products');
                    final currentUser = Hive.box<User>('users').getAt(0);

                    final product = Product(
                      name: _nameController.text,
                      description: _descriptionController.text,
                      price: double.parse(_priceController.text),
                      createdBy: currentUser?.username ?? 'unknown',
                    );

                    if (widget.index != null) {
                      // Обновление существующего продукта
                      productBox.putAt(widget.index!, product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product updated')),
                      );
                    } else {
                      // Добавление нового продукта
                      productBox.add(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added')),
                      );
                    }

                    Navigator.pop(context);
                  }
                },
                child: Text(widget.product == null ? 'Add Product' : 'Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Hive.box<User>('users').getAt(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              if (currentUser == null) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Favorites'),
                  content: const Text('Are you sure you want to clear all your favorites?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        final favoritesBox = Hive.box<FavoriteItem>('favorites');
                        final keysToDelete = <dynamic>[];

                        for (int i = 0; i < favoritesBox.length; i++) {
                          final favorite = favoritesBox.getAt(i);
                          if (favorite != null && favorite.userId == currentUser.username) {
                            keysToDelete.add(favoritesBox.keyAt(i));
                          }
                        }

                        for (final key in keysToDelete) {
                          favoritesBox.delete(key);
                        }

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All favorites cleared')),
                        );
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FavoriteItem>('favorites').listenable(),
        builder: (context, Box<FavoriteItem> box, _) {
          if (currentUser == null) {
            return const Center(child: Text('No user selected'));
          }

          // Фильтруем избранное только для текущего пользователя
          final userFavorites = box.values.where(
                  (favorite) => favorite.userId == currentUser.username
          ).toList();

          if (userFavorites.isEmpty) {
            return const Center(
              child: Text('No favorites yet. Add some!'),
            );
          }

          return ListView.builder(
            itemCount: userFavorites.length,
            itemBuilder: (context, index) {
              final favorite = userFavorites[index];

              return Dismissible(
                key: Key(favorite.key.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  box.delete(favorite.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${favorite.title} removed from favorites')),
                  );
                },
                child: ListTile(
                  title: Text(favorite.title),
                  subtitle: Text(
                    '${favorite.data.length > 50 ? favorite.data.substring(0, 50) + '...' : favorite.data}\nAdded: ${favorite.dateAdded.toString().substring(0, 16)}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          title: favorite.title,
                          data: favorite.data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Class to hold navigation arguments
class DetailArguments {
  final String title;
  final String data;

  DetailArguments({required this.title, required this.data});
}