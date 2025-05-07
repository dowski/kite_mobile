import 'package:flutter/material.dart';

void main() {
  runApp(const KiteApp());
}

class KiteApp extends StatelessWidget {
  const KiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const KiteHost(),
    );
  }
}

class KiteHost extends StatefulWidget {
  const KiteHost({super.key});

  @override
  State<KiteHost> createState() => _KiteHostState();
}

class _KiteHostState extends State<KiteHost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Kite'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
    );
  }
}
