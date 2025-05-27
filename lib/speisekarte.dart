import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Modelklasse für ein Menü-Item
class MenuItem {
  final String restaurant;
  final String tag; // z.B. "Montag"
  final String name;
  final double preis;

  MenuItem({
    required this.restaurant,
    required this.tag,
    required this.name,
    required this.preis,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
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
    // Voreinstellung für den aktuellen Wochentag (Mo–Fr), sonst keine Vorauswahl
    final weekday = DateTime.now().weekday; // 1=Mo ... 7=So
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      const dayNames = {
        DateTime.monday: 'Montag',
        DateTime.tuesday: 'Dienstag',
        DateTime.wednesday: 'Mittwoch',
        DateTime.thursday: 'Donnerstag',
        DateTime.friday: 'Freitag',
      };
      _selectedDay = dayNames[weekday];
    } else {
      _selectedDay = null;
    }
    _selectedRestaurant = null;
    _futureMenus = loadMenuItems();
  }

  Future<List<MenuItem>> loadMenuItems() async {
    final raw = await rootBundle.loadString('assets/menus/gerichte.json');
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => MenuItem.fromJson(e)).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedRestaurant = null;
      final weekday = DateTime.now().weekday;
      if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
        const dayNames = {
          DateTime.monday: 'Montag',
          DateTime.tuesday: 'Dienstag',
          DateTime.wednesday: 'Mittwoch',
          DateTime.thursday: 'Donnerstag',
          DateTime.friday: 'Freitag',
        };
        _selectedDay = dayNames[weekday];
      } else {
        _selectedDay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Was gibt\'s heute zu essen?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<MenuItem>>(
          future: _futureMenus,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            }

            final allMenus = snapshot.data!;
            // Dropdown-Listen erzeugen
            final restaurants = allMenus
                .map((m) => m.restaurant)
                .toSet()
                .toList()
              ..sort();
            final days = <String>[
              'Montag',
              'Dienstag',
              'Mittwoch',
              'Donnerstag',
              'Freitag',
            ];

            // Filter anwenden
            final filtered = allMenus.where((m) {
              final matchRest = _selectedRestaurant == null || m.restaurant == _selectedRestaurant;
              final matchDay = _selectedDay == null || m.tag == _selectedDay;
              return matchRest && matchDay;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Restaurant Dropdown
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text('Restaurant'),
                        value: _selectedRestaurant,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Alle Restaurants')),
                          ...restaurants.map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _selectedRestaurant = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tag Dropdown
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text('Tag'),
                        value: _selectedDay,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Alle Tage')),
                          ...days.map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _selectedDay = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Zurücksetzen-Button
                    ElevatedButton(
                      onPressed: _resetFilters,
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Gefilterte Ergebnisse
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Keine Treffer'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text('${item.restaurant} • ${item.tag}'),
                                trailing: Text('${item.preis.toStringAsFixed(2)} €'),
                              ),
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