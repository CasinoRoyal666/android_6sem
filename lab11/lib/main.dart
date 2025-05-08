import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Инициализация Firebase Messaging
  await setupFirebaseMessaging();

  // Инициализация Remote Config
  await setupRemoteConfig();

  runApp(const MyApp());
}

// Канал для Firebase Messaging уведомлений
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> setupFirebaseMessaging() async {
  // Запрос разрешений для iOS
  await FirebaseMessaging.instance.requestPermission();

  // Создание канала для Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Обработка фоновых сообщений
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Инициализация локальных уведомлений
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Обработка сообщений в переднем плане
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'launch_background',
          ),
        ),
      );
    }
  });

  // Получение FCM токена для тестирования
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

// Глобальная переменная для Remote Config
final remoteConfig = FirebaseRemoteConfig.instance;

Future<void> setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.setDefaults({
    'like_button_enabled': true,
    'app_theme_color': '#6750A4',
  });
  await remoteConfig.fetchAndActivate();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем цвет темы из Remote Config
    String colorHex = remoteConfig.getString('app_theme_color');
    Color themeColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return MaterialApp(
      title: 'Student Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        fontFamily: 'Arial',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomePage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLogin = true;

  Future<void> _authenticateWithEmailPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Ошибка аутентификации';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Введите email для сброса пароля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка для сброса пароля отправлена на email')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Ошибка при отправке сброса пароля';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка входа через Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  _isLogin ? 'Вход' : 'Регистрация',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // Password field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Login/Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithEmailPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                ),
                const SizedBox(height: 15),

                // Reset password button
                if (_isLogin)
                  TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text('Забыли пароль?'),
                  ),

                // Switch between login and register
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = '';
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Создать аккаунт'
                        : 'Уже есть аккаунт? Войти',
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'или',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Google sign in button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                    height: 24,
                  ),
                  label: const Text('Войти с Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });

    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы находитесь в автономном режиме. Данные будут синхронизированы при восстановлении соединения.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            DashboardScreen(pageController: _pageController), // Передаем pageController
            const LearningHubScreen(),
            const UserProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Дашборд',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Учеба',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
      floatingActionButton: _isOffline
          ? FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const Icon(Icons.wifi_off),
      )
          : null,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final PageController pageController; // Добавляем параметр

  const DashboardScreen({super.key, required this.pageController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLiked = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _editingClassId;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.fetchAndActivate();
      setState(() {}); // Обновляем UI
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }


  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await _firestore.collection('user_preferences').doc(user.uid).get();
        if (docSnapshot.exists) {
          setState(() {
            _isLiked = docSnapshot.data()?['liked_dashboard'] ?? false;
          });
        }
      } catch (e) {
        print('Error loading preferences: $e');
      }
    }
  }

  Future<void> _toggleLike() async {
    // Проверяем, включена ли кнопка лайков через Remote Config
    bool likeButtonEnabled = remoteConfig.getBool('like_button_enabled');
    if (!likeButtonEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Функция лайков временно отключена')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        setState(() {
          _isLiked = !_isLiked;
        });

        await _firestore.collection('user_preferences').doc(user.uid).set({
          'liked_dashboard': _isLiked,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Откатываем состояние при ошибке
        setState(() {
          _isLiked = !_isLiked;
        });
        print('Error updating like status: $e');
      }
    }
  }
  Future<void> _addOrUpdateClass() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется вход в аккаунт')),
      );
      return;
    }

    if (_titleController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      if (_editingClassId == null) {
        // Create
        await _firestore.collection('classes').add({
          'title': _titleController.text,
          'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
          'time': _timeController.text,
          'location': _locationController.text,
          'user_id': user.uid, // Добавляем user_id
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Занятие добавлено')),
        );
      } else {
        // Update
        await _firestore.collection('classes').doc(_editingClassId).update({
          'title': _titleController.text,
          'time': _timeController.text,
          'location': _locationController.text,
          'updated_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Занятие обновлено')),
        );
      }
      _titleController.clear();
      _timeController.clear();
      _locationController.clear();
      setState(() {
        _editingClassId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Занятие удалено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  void _editClass(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _titleController.text = data['title'];
    _timeController.text = data['time'];
    _locationController.text = data['location'];
    setState(() {
      _editingClassId = doc.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Получаем цвет из Remote Config для демонстрации
    String colorHex = remoteConfig.getString('app_theme_color');
    Color themeColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                ),
                StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Загрузка...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Студент',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      }

                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final name = data?['name'] ?? 'Студент';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Привет $name',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Студент',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    }),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Форма для добавления/редактирования
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Название занятия',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Время (например, 11:00AM)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Место',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addOrUpdateClass,
                  child: Text(_editingClassId == null ? 'Добавить занятие' : 'Обновить занятие'),
                ),
                const SizedBox(height: 20),

                // Upcoming classes from Firestore
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('classes').orderBy('date').limit(3).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Ошибка загрузки данных'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const Text('Нет запланированных занятий'),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await _firestore.collection('classes').add({
                                    'title': 'Foundation of Nursing and Midwifery',
                                    'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
                                    'time': '11:00AM',
                                    'location': 'Room 302',
                                    'user_id': user.uid, // Добавляем user_id
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Демо-занятие добавлено')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Требуется вход в аккаунт')),
                                  );
                                }
                              },
                              child: const Text('Добавить демо-занятие'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Calendar row
                        Row(
                          children: [
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
                                    'Meetings',
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

                        // Display first class as main card
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
                                    Text(
                                      '${_formatDate(snapshot.data!.docs[0]['date'])} ${snapshot.data!.docs[0]['time']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.data!.docs[0]['title'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
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
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editClass(snapshot.data!.docs[0]),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteClass(snapshot.data!.docs[0].id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 60,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to the Learning Hub
                                  widget.pageController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
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
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to user profile
                                  widget.pageController.animateToPage(
                                    2,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
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
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Профиль',
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

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  get pageController => null;

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String? _editingActivityId;

  @override
  void initState() {
    super.initState();
    remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.fetchAndActivate();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _timeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется вход в аккаунт')),
      );
      return;
    }

    if (_titleController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      final timestamp = DateTime.now().add(const Duration(hours: 2));
      if (_editingActivityId == null) {
        // Create
        await _firestore.collection('activities').add({
          'title': _titleController.text,
          'type': _typeController.text.toUpperCase(),
          'time': _timeController.text,
          'date': Timestamp.fromDate(timestamp),
          'details': [_detailsController.text],
          'user_id': user.uid,
          'created_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Активность добавлена')),
        );
      } else {
        // Update
        await _firestore.collection('activities').doc(_editingActivityId).update({
          'title': _titleController.text,
          'type': _typeController.text.toUpperCase(),
          'time': _timeController.text,
          'details': [_detailsController.text],
          'updated_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Активность обновлена')),
        );
      }
      _titleController.clear();
      _typeController.clear();
      _timeController.clear();
      _detailsController.clear();
      setState(() {
        _editingActivityId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteActivity(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется вход в аккаунт')),
      );
      return;
    }

    try {
      await _firestore.collection('activities').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Активность удалена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  void _editActivity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _titleController.text = data['title'] ?? '';
    _typeController.text = data['type'] ?? '';
    _timeController.text = data['time'] ?? '';
    _detailsController.text = (data['details'] as List<dynamic>?)?.first ?? '';
    setState(() {
      _editingActivityId = doc.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Получаем цвет из Remote Config
    String colorHex = remoteConfig.getString('app_theme_color');
    Color themeColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Верхняя панель
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок и кнопки
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              widget.pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
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
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _titleController.clear();
                            _typeController.clear();
                            _timeController.clear();
                            _detailsController.clear();
                            setState(() {
                              _editingActivityId = null;
                            });
                          },
                          tooltip: 'Новая активность',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Форма для добавления/редактирования
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название активности',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _typeController,
                      decoration: InputDecoration(
                        labelText: 'Тип (например, WORKSHOP)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Время (например, 14:00)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        labelText: 'Детали',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addOrUpdateActivity,
                      child: Text(_editingActivityId == null ? 'Добавить активность' : 'Обновить активность'),
                    ),
                    const SizedBox(height: 20),

                    // Поиск
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

                    // Быстрые действия
                    Row(
                      children: [
                        Expanded(
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

          // Основной контент
          Expanded(
            child: SingleChildScrollView(
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

                    // Today activities from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('activities')
                          .where('date',
                          isGreaterThan: Timestamp.fromDate(
                              DateTime.now().subtract(const Duration(days: 1))))
                          .orderBy('date')
                          .limit(2)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                const Text('Нет активностей на сегодня'),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _addOrUpdateActivity,
                                  child: const Text('Добавить активность'),
                                ),
                              ],
                            ),
                          );
                        }

                        return Row(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final type = data['type'] ?? 'EVENT';
                            final time = data['time'] ?? '00:00';
                            final details = List<String>.from(data['details'] ?? []);

                            Color typeColor;
                            switch (type) {
                              case 'DROP-IN':
                                typeColor = Colors.red;
                                break;
                              case 'WORKSHOP':
                                typeColor = Colors.blue;
                                break;
                              case 'ONLINE':
                                typeColor = Colors.green;
                                break;
                              default:
                                typeColor = Colors.purple;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            type,
                                            style: TextStyle(
                                              color: typeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () => _editActivity(doc),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18),
                                                onPressed: () => _deleteActivity(doc.id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: details
                                            .map((item) => _buildBulletItem(item))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
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

                    // List all activities by category
                    SizedBox(
                      height: 300, // Ограничиваем высоту списка
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('activities')
                            .orderBy('date', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('Нет доступных активностей'),
                            );
                          }

                          // Group activities by type
                          Map<String, List<DocumentSnapshot>> groupedActivities = {};
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final type = data['type'] ?? 'OTHER';
                            groupedActivities.putIfAbsent(type, () => []).add(doc);
                          }

                          return ListView.builder(
                            itemCount: groupedActivities.length,
                            itemBuilder: (context, index) {
                              final type = groupedActivities.keys.elementAt(index);
                              final activities = groupedActivities[type]!;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: _buildExpandableActivityGroup(type, activities),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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

  Widget _buildExpandableActivityGroup(
      String title, List<DocumentSnapshot> activities) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        children: activities.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final time = data['time'] ?? '00:00';
          final date = (data['date'] as Timestamp).toDate();
          final formattedDate = '${date.day}/${date.month}/${date.year}';

          return ListTile(
            title: Text('$formattedDate - $time'),
            subtitle: Text(data['details']?.first ?? 'Нет описания'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editActivity(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteActivity(doc.id),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.fetchAndActivate();
      setState(() {}); // Обновляем UI
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? 'Студент';
            _bioController.text = data['bio'] ?? 'Нет информации';
          });
        } else {
          // Создаем профиль пользователя если его нет
          final displayName = user.displayName ?? 'Студент';
          await _firestore.collection('users').doc(user.uid).set({
            'name': displayName,
            'email': user.email,
            'bio': 'Нет информации',
            'created_at': FieldValue.serverTimestamp(),
          });

          _nameController.text = displayName;
          _bioController.text = 'Нет информации';
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлен')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления профиля: $e')),
        );
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Навигация происходит автоматически через StreamBuilder в MyApp
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Получаем цвет из Remote Config для демонстрации работы
    String colorHex = remoteConfig.getString('app_theme_color');
    Color themeColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text('Профиль пользователя'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Получаем цвет темы из RemoteConfig
          String colorHex = remoteConfig.getString('app_theme_color');
          Color themeColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

          return SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Заголовок профиля
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {},
                          ),
                          const Expanded(
                            child: Text(
                              'Ваш профиль',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isEditing ? Icons.save : Icons.edit),
                            onPressed: () {
                              if (_isEditing) {
                                _saveUserData();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Аватар пользователя (с использованием themeColor)
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: themeColor.withOpacity(0.2),
                        child: user?.photoURL != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.network(
                            user!.photoURL!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Icon(
                          Icons.person,
                          size: 60,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Данные пользователя
                      if (_isEditing)
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        )
                      else
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 10),

                      Text(
                        user?.email ?? 'Нет email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Блок "О себе"
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
                              'О себе',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_isEditing)
                              TextField(
                                controller: _bioController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            else
                              Text(
                                _bioController.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Блок информации об аккаунте
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
                              'Информация аккаунта',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow('Провайдер', _getProviderName(user)),
                            const Divider(),
                            _buildInfoRow('UUID', user?.uid ?? 'Нет UID'),
                            const Divider(),
                            _buildInfoRow('Email Verified',
                                user?.emailVerified == true ? 'Да' : 'Нет'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Блок RemoteConfig (с использованием themeColor)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeColor),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Firebase Remote Config Demo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Тема приложения: $colorHex',
                              style: TextStyle(color: themeColor),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Кнопка лайка: ${remoteConfig.getBool(
                                  'like_button_enabled')
                                  ? "Включена"
                                  : "Отключена"}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Кнопка выхода
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Выйти из аккаунта'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Оставляем вертикальные отступы
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верху, если значение переносится
        children: [
          Text( // Метка
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey, // Можно сделать чуть темнее для читаемости: Colors.grey[600]
            ),
          ),
          const SizedBox(width: 16), // Добавляем явный отступ между меткой и значением
          Flexible( // Оборачиваем значение в Flexible
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end, // Опционально: выровнять текст значения по правому краю
              // softWrap: true, // Разрешает перенос текста (включено по умолчанию)
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderName(User? user) {
    if (user == null) return 'Не авторизован';

    if (user.providerData.isEmpty) return 'Неизвестный провайдер';

    switch (user.providerData[0].providerId) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email/Password';
      case 'github.com':
        return 'GitHub';
      case 'microsoft.com':
        return 'Microsoft';
      default:
        return user.providerData[0].providerId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}