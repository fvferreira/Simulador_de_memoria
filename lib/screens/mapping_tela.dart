import 'package:flutter/material.dart';

import '../models/pagina_modelo.dart';
import '../utils/color_utils.dart';

class MappingScreen extends StatelessWidget {
  final PagingModel model;

  const MappingScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mapeamento entre páginas e quadros',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cada bloco da memória lógica (página) é colorido de acordo com o '
                'quadro da memória física para o qual ele está mapeado. Blocos '
                'cinza indicam páginas sem quadro associado (ainda não '
                'carregadas) ou quadros livres.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        model.gerarMapeamentoAutomatico(aleatorio: false),
                    icon: const Icon(Icons.sort),
                    label: const Text('Mapeamento sequencial'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        model.gerarMapeamentoAutomatico(aleatorio: true),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Mapeamento aleatório'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MemoriaColuna(
                        titulo: 'Memória lógica (páginas)',
                        quantidade: model.numPages,
                        corDoIndice: (i) => colorForIndex(i),
                        rotulo: (i) => 'Página $i',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _MemoriaColuna(
                        titulo: 'Memória física (quadros)',
                        quantidade: model.numFrames,
                        corDoIndice: (frame) {
                          final pagina = model.pageTable.indexOf(frame);
                          return pagina == -1
                              ? corSemMapeamento
                              : colorForIndex(pagina);
                        },
                        rotulo: (frame) {
                          final pagina = model.pageTable.indexOf(frame);
                          return pagina == -1
                              ? 'Quadro $frame (livre)'
                              : 'Quadro $frame ← Página $pagina';
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _TabelaDePaginas(model: model)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemoriaColuna extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final Color Function(int) corDoIndice;
  final String Function(int) rotulo;

  const _MemoriaColuna({
    required this.titulo,
    required this.quantidade,
    required this.corDoIndice,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: quantidade == 0
                ? const Center(child: Text('Vazio'))
                : ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: quantidade,
                    itemExtent: 36,
                    itemBuilder: (context, index) {
                      final cor = corDoIndice(index);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 4,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.3),
                          border: Border.all(color: cor, width: 1.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rotulo(index),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _TabelaDePaginas extends StatelessWidget {
  final PagingModel model;

  const _TabelaDePaginas({required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tabela de páginas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.grey.shade200,
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Página',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Página (bin)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Quadro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: model.numPages,
            itemBuilder: (context, pagina) {
              final quadro = model.pageTable[pagina];
              final binPagina = pagina
                  .toRadixString(2)
                  .padLeft(model.pageBits, '0');
              return Container(
                color: pagina.isEven ? null : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('$pagina')),
                    Expanded(
                      flex: 3,
                      child: Text(
                        binPagina,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButton<int?>(
                        isDense: true,
                        value: quadro,
                        hint: const Text('— (ausente)'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('— (ausente)'),
                          ),
                          for (var f = 0; f < model.numFrames; f++)
                            DropdownMenuItem<int?>(
                              value: f,
                              child: Text('Quadro $f'),
                            ),
                        ],
                        onChanged: (novoQuadro) =>
                            model.definirQuadro(pagina, novoQuadro),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
