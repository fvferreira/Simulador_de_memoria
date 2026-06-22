import 'package:flutter/material.dart';

import '../models/pagina_modelo.dart';
import '../widgets/bit_box_row.dart';

enum _ModoEntrada { paginaEDeslocamento, enderecoCompleto }

class TranslationScreen extends StatefulWidget {
  final PagingModel model;

  const TranslationScreen({super.key, required this.model});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  _ModoEntrada _modo = _ModoEntrada.paginaEDeslocamento;

  final _enderecoController = TextEditingController(text: '0');
  final _deslocamentoController = TextEditingController(text: '0');
  int _paginaSelecionada = 0;

  TraducaoResultado? _resultado;

  @override
  void dispose() {
    _enderecoController.dispose();
    _deslocamentoController.dispose();
    super.dispose();
  }

  void _traduzir() {
    final model = widget.model;
    int? endereco;

    if (_modo == _ModoEntrada.enderecoCompleto) {
      endereco = int.tryParse(_enderecoController.text.trim());
      if (endereco == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um número inteiro válido.')),
        );
        return;
      }
    } else {
      final deslocamento = int.tryParse(_deslocamentoController.text.trim());
      if (deslocamento == null ||
          deslocamento < 0 ||
          deslocamento >= model.pageSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O deslocamento deve estar entre 0 e ${model.pageSize - 1}.',
            ),
          ),
        );
        return;
      }
      final paginaValida = _paginaSelecionada
          .clamp(0, model.numPages - 1)
          .toInt();
      endereco = paginaValida * model.pageSize + deslocamento;
    }

    setState(() {
      _resultado = model.traduzir(endereco!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        final paginaValida = _paginaSelecionada
            .clamp(0, model.numPages - 1)
            .toInt();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tradução de endereço',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe um endereço dentro de uma página (ou um endereço lógico '
                  'completo) e veja, passo a passo, como ele é traduzido para um '
                  'endereço físico usando a tabela de páginas atual.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<_ModoEntrada>(
                  segments: const [
                    ButtonSegment(
                      value: _ModoEntrada.paginaEDeslocamento,
                      label: Text('Página + deslocamento'),
                      icon: Icon(Icons.view_column),
                    ),
                    ButtonSegment(
                      value: _ModoEntrada.enderecoCompleto,
                      label: Text('Endereço lógico completo'),
                      icon: Icon(Icons.numbers),
                    ),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (novo) =>
                      setState(() => _modo = novo.first),
                ),
                const SizedBox(height: 16),
                if (_modo == _ModoEntrada.paginaEDeslocamento)
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      DropdownButton<int>(
                        value: paginaValida,
                        items: [
                          for (var p = 0; p < model.numPages; p++)
                            DropdownMenuItem<int>(
                              value: p,
                              child: Text('Página $p'),
                            ),
                        ],
                        onChanged: (p) =>
                            setState(() => _paginaSelecionada = p ?? 0),
                      ),
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _deslocamentoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Deslocamento (d)',
                            helperText: '0 a ${model.pageSize - 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _enderecoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Endereço lógico',
                        helperText: '0 a ${model.logicalMemorySize - 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _traduzir,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Traduzir'),
                ),
                const SizedBox(height: 32),
                if (_resultado != null)
                  _ResultadoTraducao(resultado: _resultado!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultadoTraducao extends StatelessWidget {
  final TraducaoResultado resultado;

  const _ResultadoTraducao({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final model = resultado.model;

    if (!resultado.sucesso) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resultado.motivoFalha ?? 'Endereço inválido.',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pagina = resultado.pagina!;
    final deslocamento = resultado.deslocamento!;
    final quadro = resultado.quadro!;
    final fisico = resultado.enderecoFisico!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço lógico ${resultado.enderecoLogico} → endereço físico $fisico',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('1. Decomposição do endereço lógico:'),
            const SizedBox(height: 8),
            BitBoxRow(
              groups: [
                BitGroup(
                  label: 'p (página)',
                  bitCount: model.pageBits,
                  value: pagina,
                  color: Colors.indigo,
                ),
                BitGroup(
                  label: 'd (deslocamento)',
                  bitCount: model.n,
                  value: deslocamento,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '2. Consulta à tabela de páginas: página $pagina → quadro $quadro.',
            ),
            const SizedBox(height: 16),
            const Text('3. Endereço físico (quadro + deslocamento):'),
            const SizedBox(height: 8),
            BitBoxRow(
              groups: [
                BitGroup(
                  label: 'f (quadro)',
                  bitCount: model.frameBits,
                  value: quadro,
                  color: Colors.deepOrange,
                ),
                BitGroup(
                  label: 'd (deslocamento)',
                  bitCount: model.n,
                  value: deslocamento,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cálculo: endereço físico = quadro × tamanho da página + deslocamento '
              '= $quadro × ${model.pageSize} + $deslocamento = $fisico.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
