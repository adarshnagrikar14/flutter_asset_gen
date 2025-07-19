import 'generated/assets.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Asset Gen Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Asset Gen Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generated Asset Constants',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Example usage of generated assets
            const Text(
              'Class-based usage:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Assets.logoPng = ${Assets.logoPng}'),
            Text('Assets.iconSvg = ${Assets.iconSvg}'),

            const SizedBox(height: 16),

            const Text(
              'Map-based usage:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Assets.all[\'logoPng\'] = ${Assets.all['logoPng']}'),
            Text('Assets.all[\'iconSvg\'] = ${Assets.all['iconSvg']}'),

            const SizedBox(height: 16),

            const Text(
              'All available assets:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: Assets.all.length,
                itemBuilder: (context, index) {
                  final key = Assets.all.keys.elementAt(index);
                  final value = Assets.all[key]!;
                  return ListTile(
                    title: Text(key),
                    subtitle: Text(value),
                    trailing: const Icon(Icons.image),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
