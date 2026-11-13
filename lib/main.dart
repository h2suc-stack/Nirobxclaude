import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const App());

const slate = Color(0xFF1E293B);
const amber = Color(0xFFF59E0B);

String f(double x, int d) => x.toStringAsFixed(d);

class App extends StatelessWidget {
  const App({super.key});
  ThemeData _t(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: slate, brightness: b),
      );
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Civil Calculator',
        theme: _t(Brightness.light),
        darkTheme: _t(Brightness.dark),
        home: const CalcPage(),
      );
}

class Spec {
  final double steel;
  final List<String> labels;
  final List<double> defs;
  const Spec(this.steel, this.labels, this.defs);
}

const specs = <String, Spec>{
  'Beam': Spec(120, ['Width (m)', 'Depth (m)', 'Length (m)'], [0.23, 0.45, 4]),
  'Column': Spec(150, ['Width (m)', 'Depth (m)', 'Height (m)'], [0.3, 0.3, 3]),
  'Slab': Spec(80, ['Length (m)', 'Width (m)', 'Thickness (m)'], [5, 4, 0.15]),
  'Pile': Spec(100, ['Diameter (m)', 'Length (m)'], [0.45, 12]),
};

const mixes = <String, List<double>>{
  'M20 (1 : 1.5 : 3)': [1, 1.5, 3],
  'M15 (1 : 2 : 4)': [1, 2, 4],
  'M25 (1 : 1 : 2)': [1, 1, 2],
};

class Item {
  final String name;
  final double vol, bags, steel;
  Item(this.name, this.vol, this.bags, this.steel);
}

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});
  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  String cur = 'Beam';
  String mix = mixes.keys.first;
  List<TextEditingController> dims = [];
  final qty = TextEditingController(text: '1');
  final steel = TextEditingController();
  final items = <Item>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final s = specs[cur]!;
    dims = [for (final d in s.defs) TextEditingController(text: '$d')];
    steel.text = f(s.steel, 0);
  }

  double n(TextEditingController c) => double.tryParse(c.text) ?? 0;

  Map<String, double> calc() {
    final v = dims.map(n).toList();
    final one = cur == 'Pile' ? pi * v[0] * v[0] / 4 * v[1] : v[0] * v[1] * v[2];
    final vol = one * n(qty);
    final m = mixes[mix]!;
    final sum = m[0] + m[1] + m[2];
    final dry = vol * 1.54;
    return {
      'one': one,
      'vol': vol,
      'bags': dry * m[0] / sum / 0.0347,
      'sand': dry * m[1] / sum,
      'agg': dry * m[2] / sum,
      'steel': vol * n(steel),
    };
  }

  Widget field(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
      );

  Widget row(String a, String b) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a, style: const TextStyle(color: Colors.white70)),
            Text(b, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = calc();
    final tv = items.fold(0.0, (a, i) => a + i.vol);
    final tb = items.fold(0.0, (a, i) => a + i.bags);
    final ts = items.fold(0.0, (a, i) => a + i.steel);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Civil Estimate Calculator'),
        backgroundColor: slate,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final k in specs.keys) ButtonSegment(value: k, label: Text(k))
            ],
            selected: {cur},
            onSelectionChanged: (s) => setState(() {
              cur = s.first;
              load();
            }),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < dims.length; i++)
            field(specs[cur]!.labels[i], dims[i]),
          field('Number of units', qty),
          field('Steel (kg per m³)', steel),
          DropdownButtonFormField<String>(
            value: mix,
            decoration: const InputDecoration(
                labelText: 'Concrete mix', border: OutlineInputBorder()),
            items: [
              for (final k in mixes.keys)
                DropdownMenuItem(value: k, child: Text(k))
            ],
            onChanged: (v) => setState(() => mix = v!),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: slate,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Concrete volume',
                    style: TextStyle(color: Colors.white70)),
                Text('${f(r['vol']!, 3)} m³',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: amber)),
                row('Per unit', '${f(r['one']!, 3)} m³'),
                row('Cement', '${f(r['bags']!, 1)} bags'),
                row('Sand', '${f(r['sand']!, 2)} m³'),
                row('Aggregate', '${f(r['agg']!, 2)} m³'),
                row('Steel', '${f(r['steel']!, 1)} kg'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: amber,
                foregroundColor: slate,
                padding: const EdgeInsets.all(14)),
            onPressed: r['vol']! > 0
                ? () => setState(() => items.add(Item(
                    '$cur × ${f(n(qty), 0)}', r['vol']!, r['bags']!, r['steel']!)))
                : null,
            child: const Text('Add to estimate'),
          ),
          const SizedBox(height: 20),
          const Text('Estimate list',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Add items to build a project total.'),
            ),
          for (var i = 0; i < items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(items[i].name),
              subtitle: Text(
                  '${f(items[i].vol, 3)} m³, ${f(items[i].bags, 1)} bags, ${f(items[i].steel, 0)} kg'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => items.removeAt(i)),
              ),
            ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Total: ${f(tv, 3)} m³, ${f(tb, 1)} bags, ${f(ts, 0)} kg steel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Estimates only. Add your site wastage allowance before ordering.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
