import 'package:flutter/material.dart';

import '../models/pagina_modelo.dart';
import '../widgets/bit_box_row.dart';

class ConfigScreen extends StatefulWidget {
  final PagingModel model;

  const ConfigScreen({super.key, required this.model});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pageSizeController;
  late TextEditingController _logicalSizeController;
  late TextEditingController _physicalSizeController;

  @override
  void initState() {
    super.initState();
    _pageSizeController = TextEditingController(
      text: widget.model.pageSize.toString(),
    );
    _logicalSizeController = TextEditingController(
      text: widget.model.logicalMemorySize.toString(),
    );
    _physicalSizeController = TextEditingController(
      text: widget.model.physicalMemorySize.toString(),
    );
  }

  @override
  void dispose() {
    _pageSizeController.dispose();
    _logicalSizeController.dispose();
    _physicalSizeController.dispose();
    super.dispose();
  }

  String? _validatePowerOfTwo(String? value, String rotulo) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o $rotulo.';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      return '$rotulo deve ser um número inteiro positivo.';
    }
    if (!PagingModel.isPowerOfTwo(n)) {
      return '$rotulo deve ser uma potência de 2 (ex.: 256, 512, 1024...).';
    }
    return null;
  }

  void _aplicar() {
    if (!_formKey.currentState!.validate()) return;

    final pageSize = int.parse(_pageSizeController.text.trim());
    final logicalSize = int.parse(_logicalSizeController.text.trim());
    final physicalSize = int.parse(_physicalSizeController.text.trim());

    try {
      widget.model.configurar(
        pageSize: pageSize,
        logicalMemorySize: logicalSize,
        physicalMemorySize: physicalSize,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuração aplicada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Invalid argument(s): ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração da memória',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Defina o tamanho da página e os tamanhos das memórias lógica e '
                  'física. Todos os valores são expressos em bytes e precisam ser '
                  'potências de 2, assim como ocorre na maioria das arquiteturas '
                  'reais — isso é o que torna trivial separar um endereço em '
                  'número de página e deslocamento.',
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _pageSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Tamanho da página (bytes)',
                          border: OutlineInputBorder(),
                          helperText: 'Ex.: 4096',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePowerOfTwo(v, 'tamanho da página'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _logicalSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Tamanho da memória lógica (bytes)',
                          border: OutlineInputBorder(),
                          helperText: 'Espaço de endereçamento de um processo',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePowerOfTwo(v, 'tamanho da memória lógica'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _physicalSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Tamanho da memória física (bytes)',
                          border: OutlineInputBorder(),
                          helperText: 'RAM disponível no sistema simulado',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePowerOfTwo(v, 'tamanho da memória física'),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _aplicar,
                          icon: const Icon(Icons.check),
                          label: const Text('Aplicar configuração'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text('Resumo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ResumoTabela(model: model),
                const SizedBox(height: 32),
                Text(
                  'Formato do endereço lógico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Um endereço lógico de ${model.m} bits é dividido em um número de '
                  'página (p) com ${model.pageBits} bits e um deslocamento (d) com '
                  '${model.n} bits dentro da página:',
                ),
                const SizedBox(height: 12),
                BitBoxRow(
                  groups: [
                    BitGroup(
                      label: 'p (página)',
                      bitCount: model.pageBits,
                      value: 0,
                      color: Colors.indigo,
                    ),
                    BitGroup(
                      label: 'd (deslocamento)',
                      bitCount: model.n,
                      value: 0,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResumoTabela extends StatelessWidget {
  final PagingModel model;

  const _ResumoTabela({required this.model});

  @override
  Widget build(BuildContext context) {
    final linhas = <List<String>>[
      ['Número de páginas', model.numPages.toString()],
      ['Número de quadros', model.numFrames.toString()],
      ['Bits do endereço lógico (m)', model.m.toString()],
      ['Bits do deslocamento (n)', model.n.toString()],
      ['Bits do número de página', model.pageBits.toString()],
      ['Bits do número de quadro', model.frameBits.toString()],
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      children: [
        for (final linha in linhas)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(linha[0]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  linha[1],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
