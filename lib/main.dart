import 'package:flutter/material.dart';

import 'models/pagina_modelo.dart';
import 'screens/config_tela.dart';
import 'screens/mapping_tela.dart';
import 'screens/tradutor_tela.dart';

void main() {
  runApp(const SimuladorApp());
}

class SimuladorApp extends StatelessWidget {
  const SimuladorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador de Paginação de Memória',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PagingModel _model;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _model = PagingModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ConfigScreen(model: _model),
      MappingScreen(model: _model),
      TranslationScreen(model: _model),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Simulador de Paginação de Memória — Sistemas Operacionais',
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.tune),
                label: Text('Configuração'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grid_view),
                label: Text('Mapeamento'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.swap_horiz),
                label: Text('Tradução'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: screens),
          ),
        ],
      ),
    );
  }
}
