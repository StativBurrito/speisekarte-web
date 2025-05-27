import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Modelklasse für ein Menü-Item
typedef JsonMap = Map<String, dynamic>;
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
  const Speisekarte({Key? key}) : super(key: key);

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
    // Voreinstellung für aktuellen Wochentag (Mo–Fr), sonst null
    final wd = DateTime.now().weekday;
    const dayNames = {
      DateTime.monday: 'Montag',
      DateTime.tuesday: 'Dienstag',
      DateTime.wednesday: 'Mittwoch',
      DateTime.thursday: 'Donnerstag',
      DateTime.friday: 'Freitag',
    };
    _selectedDay = (wd >= DateTime.monday && wd <= DateTime.friday)
        ? dayNames[wd]
        : null;
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
      _selectedDay = (wd >= DateTime.monday && wd <= DateTime.friday)
          ? dayNames[wd]
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Was gibt's heute zu essen?"),
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
          builder: (ctx, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            }

            final allMenus = snapshot.data!;
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
              'Freitag'
            ];

            final filtered = allMenus.where((m) {
              final okRest = _selectedRestaurant == null ||
                  m.restaurant == _selectedRestaurant;
              final okDay = _selectedDay == null || m.tag == _selectedDay;
              return okRest && okDay;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Responsive Filter-Menü
                LayoutBuilder(
                  builder: (context, cons) {
                    final isMobile = cons.maxWidth < 600;
                    final filters = [
                      // Restaurant Dropdown
                      Expanded(
                        child: DropdownButton<String>(
                          hint: const Text('Restaurant'),
                          value: _selectedRestaurant,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Alle Restaurants')),
                            ...restaurants
                                .map((r) =>
                                    DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                          ],
                          onChanged: (v) => setState(() => _selectedRestaurant = v),
                        ),
                      ),
                      const SizedBox(width: 8, height: 8),
                      // Tag Dropdown
                      Expanded(
                        child: DropdownButton<String>(
                          hint: const Text('Tag'),
                          value: _selectedDay,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Alle Tage')),
                            ...days
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                          ],
                          onChanged: (v) => setState(() => _selectedDay = v),
                        ),
                      ),
                      const SizedBox(width: 8, height: 8),
                      // Reset Button
                      ElevatedButton(
                        onPressed: _resetFilters,
                        child: const Text('Zurücksetzen'),
                      ),
                    ];
                    return isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: filters,
                          )
                        : Row(children: filters);
                  },
                ),
                const SizedBox(height: 16),
                // Ergebnisliste mit Divider
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Keine Treffer'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('${item.restaurant} • ${item.tag}'),
                              trailing:
                                  Text('${item.preis.toStringAsFixed(2)} €'),
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