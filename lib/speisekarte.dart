import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

typedef JsonMap = Map<String, dynamic>;

// Modelklasse für ein Menü-Item
class MenuItem {
  final String restaurant;
  final String tag;
  final String name;
  final double preis;

  MenuItem({
    required this.restaurant,
    required this.tag,
    required this.name,
    required this.preis,
  });

  factory MenuItem.fromJson(JsonMap json) {
    return MenuItem(
      restaurant: json['Restaurant'] as String,
      tag: json['Tag'] as String,
      name: json['Gericht Name'] as String,
      preis: (json['Gericht Preis'] as num).toDouble(),
    );
  }
}

class Speisekarte extends StatefulWidget {
  const Speisekarte({super.key});

  @override
  State<Speisekarte> createState() => _SpeisekarteState();
}

class _SpeisekarteState extends State<Speisekarte> {
  late Future<List<MenuItem>> _futureMenus;
  String? _selectedRestaurant;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    const dayNames = {
      DateTime.monday: 'Montag',
      DateTime.tuesday: 'Dienstag',
      DateTime.wednesday: 'Mittwoch',
      DateTime.thursday: 'Donnerstag',
      DateTime.friday: 'Freitag',
    };
    _selectedDay =
        (wd >= DateTime.monday && wd <= DateTime.friday) ? dayNames[wd] : null;
    _selectedRestaurant = null;
    _futureMenus = loadMenuItems();
  }

  Future<List<MenuItem>> loadMenuItems() async {
    final raw = await rootBundle.loadString('assets/menus/gerichte.json');
    final List<dynamic> data = jsonDecode(raw);
    return data.map((e) => MenuItem.fromJson(e as JsonMap)).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedRestaurant = null;
      final wd = DateTime.now().weekday;
      const dayNames = {
        DateTime.monday: 'Montag',
        DateTime.tuesday: 'Dienstag',
        DateTime.wednesday: 'Mittwoch',
        DateTime.thursday: 'Donnerstag',
        DateTime.friday: 'Freitag',
      };
      _selectedDay =
          (wd >= DateTime.monday && wd <= DateTime.friday)
              ? dayNames[wd]
              : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Was gibt's heute zu essen?"),
            const SizedBox(width: 8),
            Icon(Icons.restaurant_menu, color: iconColor),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<MenuItem>>(
          future: _futureMenus,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            }

            final allMenus = snapshot.data!;
            final restaurants =
                allMenus.map((m) => m.restaurant).toSet().toList()..sort();
            final days = <String>[
              'Montag',
              'Dienstag',
              'Mittwoch',
              'Donnerstag',
              'Freitag',
            ];

            final filtered =
                allMenus.where((m) {
                  final okRest =
                      _selectedRestaurant == null ||
                      m.restaurant == _selectedRestaurant;
                  final okDay = _selectedDay == null || m.tag == _selectedDay;
                  return okRest && okDay;
                }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ChoiceChips für Restaurants
                Text(
                  'Restaurant auswählen:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Center(),
                Wrap(
                  runSpacing: 20,
                  spacing: 20,
                  children: [
                    ChoiceChip(
                      label: const Text('Alle'),
                      selected: _selectedRestaurant == null,
                      onSelected:
                          (_) => setState(() => _selectedRestaurant = null),
                    ),
                    ...restaurants.map(
                      (r) => ChoiceChip(
                        label: Text(r),
                        selected: _selectedRestaurant == r,
                        onSelected:
                            (_) => setState(() => _selectedRestaurant = r),
                      ),
                    ),
                    Divider()
                  ],
                ),
                const SizedBox(height: 25),
                // ChoiceChips für Tage
                Text(
                  'Tag auswählen:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  runSpacing: 20,
                  spacing: 20,
                  children: [
                    ChoiceChip(
                      label: const Text('Alle'),
                      selected: _selectedDay == null,
                      onSelected: (_) => setState(() => _selectedDay = null),
                    ),
                    ...days.map(
                      (d) => ChoiceChip(
                        label: Text(d),
                        selected: _selectedDay == d,
                        onSelected: (_) => setState(() => _selectedDay = d),
                      ),
                    ),
                    Divider()
                  ],
                ),
                const SizedBox(height: 16),
                // Reset-Button
                ElevatedButton(
                  onPressed: _resetFilters,
                  child: const Text('Zurücksetzen'),
                ),
                const SizedBox(height: 16),
                // Gefilterte Liste mit Restaurant-Header
                Expanded(
                  child:
                      filtered.isEmpty
                          ? const Center(child: Text('Keine Treffer'))
                          : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final item = filtered[idx];
                              final isNewGroup =
                                  idx == 0 ||
                                  item.restaurant !=
                                      filtered[idx - 1].restaurant;
                              List<Widget> children = [];
                              if (isNewGroup) {
                                children.add(const SizedBox(height: 20));
                                children.add(const Divider());
                                children.add(
                                  Row(
                                    children: [
                                      // Platzhalter-Logo
                                      Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        item.restaurant,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                children.add(const SizedBox(height: 8));
                              }
                              children.add(
                                ListTile(
                                  title: Text(item.name),
                                  subtitle: Text(item.tag),
                                  trailing: Text(
                                    '${item.preis.toStringAsFixed(2)} €',
                                  ),
                                ),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: children,
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
