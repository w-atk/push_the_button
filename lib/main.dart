import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';
import 'package:fl_chart/fl_chart.dart';

// Data class for chart points
class CounterPoint {
  final DateTime timestamp;
  final int value;
  
  CounterPoint({required this.timestamp, required this.value});
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'value': value,
  };
  
  factory CounterPoint.fromJson(Map<String, dynamic> json) => CounterPoint(
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    value: json['value'],
  );
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('highscoreBox');
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
  List<CounterPoint> _counterHistory = [];

  void _incrementCounter() async {
    setState(() {
      _counter += _incrementValue;
      _counterHistory.add(CounterPoint(
        timestamp: DateTime.now(),
        value: _counter,
      ));
      if (_counter > _highScore) {
        _highScore = _counter;
        _saveHighScore();
      }
      _saveCounterHistory();
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
    _box = Hive.box('highscoreBox');
    _loadHighScore();
    _loadCounterHistory();
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

  void _saveCounterHistory() async {
    if (_box != null) {
      final historyJson = _counterHistory.map((point) => point.toJson()).toList();
      await _box!.put('counterHistory', historyJson);
    }
  }

  void _loadCounterHistory() async {
    if (_box != null) {
      final historyJson = _box!.get('counterHistory', defaultValue: <dynamic>[]);
      if (historyJson is List) {
        setState(() {
          _counterHistory = historyJson
              .map<CounterPoint>((json) => CounterPoint.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        });
      }
    }
  }

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
            // Counter Chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: _counterHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No counter data yet.\nStart clicking to see your progress!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (_counterHistory.isEmpty) return const Text('');
                                final index = value.toInt();
                                if (index >= 0 && index < _counterHistory.length) {
                                  final point = _counterHistory[index];
                                  return Text(
                                    '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 22,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _counterHistory.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
                            }).toList(),
                            isCurved: true,
                            color: Colors.teal.shade700,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.teal.shade700.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _upgradeIncrement,
              child: const Text('Upgrade Power Level'),
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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counterHistory.clear();
                });
                _saveCounterHistory();
              },
              child: const Text('Clear Chart History'),
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
