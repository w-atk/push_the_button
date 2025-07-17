import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.initFlutter();
  if (Platform.isWindows) {
    // setWindowMinSize(const Size(1080, 2400));
    // setWindowMaxSize(const Size(1080, 2400));
    setWindowFrame(const Rect.fromLTWH(0, 0, 360, 780));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThemeSwitcher();
  }
}

class ThemeSwitcher extends StatefulWidget {
  const ThemeSwitcher({super.key});

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PUSH THE BUTTON!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 39, 4, 63),
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
        brightness: _isDark ? Brightness.dark : Brightness.light,
      ),
      home: MyHomePage(
        title: 'PUSH THE BUTTON!',
        onToggleTheme: () {
          setState(() {
            _isDark = !_isDark;
          });
        },
        isDark: true
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final void Function()? onToggleTheme;
  final bool isDark;
  const MyHomePage({super.key, required this.title, this.onToggleTheme, this.isDark = false});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _incrementValue = 1;
  int _xp = 10;
  int _highScore = 0;
  DateTime? _lastXpUpdate;
  Box? _box;

  void _incrementCounter() async {
    setState(() {
      _counter += _incrementValue;
      if (_counter > _highScore) {
        _highScore = _counter;
        _saveHighScore();
      }
    });
  }

  void _upgradeIncrement() {
    setState(() {
      int newValue = _incrementValue + 1;
      _incrementValue = newValue <= _xp ? newValue : _xp;
    });
  }

  void _updateXp() {
    final now = DateTime.now();
    if (_lastXpUpdate == null) {
      _lastXpUpdate = now;
      return;
    }
    final secondsPassed = now.difference(_lastXpUpdate!).inSeconds;
    if (secondsPassed >= 3) {
      setState(() {
        int increments = secondsPassed ~/ 3;
        _xp += increments;
        if (_incrementValue > _xp) {
          _incrementValue = _xp;
        }
      });
      _lastXpUpdate = now;
    }
  }

  @override
  void initState() {
    super.initState();
    _initHive();
    _lastXpUpdate = DateTime.now();
    Future.delayed(const Duration(seconds: 1), _startXpTimer);

  }

  Future<void> _initHive() async {
    _box = await Hive.openBox('highscoreBox');
    _loadHighScore();
  }

  void _startXpTimer() {
    // Use periodic timer to update XP every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      _updateXp();
      return true;
    });
  }

  void _loadHighScore() async {
    if (_box != null) {
      setState(() {
        _highScore = _box!.get('highScore', defaultValue: 0);
      });
    }
  }

  void _saveHighScore() async {
    if (_box != null) {
      await _box!.put('highScore', _highScore);
    }
  }

  // Removed duplicate _upgradeIncrement method

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hey Reid, how high can this number go?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'XP: $_xp',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              'High Score: $_highScore',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _upgradeIncrement,
              child: const Text('Upgrade'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Power Level'),
                    content: Text('Increment Value: $_incrementValue'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Power Level'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
