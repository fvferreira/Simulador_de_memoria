import 'package:flutter/material.dart';

/// Representa um grupo de bits dentro de um endereço — por exemplo,
/// os bits que formam o número da página, ou os bits que formam o
/// deslocamento dentro da página.
class BitGroup {
  final String label;
  final int bitCount;
  final int value;
  final Color color;

  const BitGroup({
    required this.label,
    required this.bitCount,
    required this.value,
    required this.color,
  });
}

/// Desenha um endereço como uma sequência de "caixinhas" de bits,
/// agrupadas e coloridas de acordo com cada [BitGroup].
///
/// É usado tanto para ilustrar o formato geral de um endereço
/// (número de página | deslocamento) quanto para mostrar o valor
/// binário real de um endereço específico durante a tradução.
class BitBoxRow extends StatelessWidget {
  final List<BitGroup> groups;
  final double boxSize;

  const BitBoxRow({super.key, required this.groups, this.boxSize = 26});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final group in groups) _buildGroup(group)],
      ),
    );
  }

  Widget _buildGroup(BitGroup group) {
    if (group.bitCount <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: group.color,
              ),
            ),
            const SizedBox(height: 4),
            const Text('(0 bits)', style: TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    final binCompleto = group.value
        .toRadixString(2)
        .padLeft(group.bitCount, '0');
    final bits = binCompleto.length > group.bitCount
        ? binCompleto.substring(binCompleto.length - group.bitCount)
        : binCompleto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.label} (${group.bitCount} bits)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: group.color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final bit in bits.split(''))
                Container(
                  width: boxSize,
                  height: boxSize,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.15),
                    border: Border.all(color: group.color, width: 1.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bit,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: group.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('= ${group.value}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
