import 'dart:math';

import 'package:flutter/foundation.dart';

class PagingModel extends ChangeNotifier {
  int _pageSize = 4096;
  int _logicalMemorySize = 65536;
  int _physicalMemorySize = 32768;

  List<int?> _pageTable = [];

  PagingModel() {
    gerarMapeamentoAutomatico();
  }

  int get pageSize => _pageSize;
  int get logicalMemorySize => _logicalMemorySize;
  int get physicalMemorySize => _physicalMemorySize;

  int get numPages => _logicalMemorySize ~/ _pageSize;

  int get numFrames => _physicalMemorySize ~/ _pageSize;

  int get m => _log2(_logicalMemorySize);

  int get n => _log2(_pageSize);

  int get pageBits => m - n;

  int get frameBits => _log2(_physicalMemorySize) - n;

  int get physicalAddressBits => _log2(_physicalMemorySize);

  List<int?> get pageTable => List.unmodifiable(_pageTable);

  static int _log2(int value) => (log(value) / log(2)).round();

  static bool isPowerOfTwo(int value) =>
      value > 0 && (value & (value - 1)) == 0;

  void configurar({
    required int pageSize,
    required int logicalMemorySize,
    required int physicalMemorySize,
  }) {
    if (!isPowerOfTwo(pageSize)) {
      throw ArgumentError('O tamanho da página precisa ser uma potência de 2.');
    }
    if (!isPowerOfTwo(logicalMemorySize)) {
      throw ArgumentError(
        'O tamanho da memória lógica precisa ser uma potência de 2.',
      );
    }
    if (!isPowerOfTwo(physicalMemorySize)) {
      throw ArgumentError(
        'O tamanho da memória física precisa ser uma potência de 2.',
      );
    }
    if (pageSize > logicalMemorySize) {
      throw ArgumentError(
        'O tamanho da página não pode ser maior que a memória lógica.',
      );
    }
    if (pageSize > physicalMemorySize) {
      throw ArgumentError(
        'O tamanho da página não pode ser maior que a memória física.',
      );
    }

    _pageSize = pageSize;
    _logicalMemorySize = logicalMemorySize;
    _physicalMemorySize = physicalMemorySize;
    gerarMapeamentoAutomatico();
  }

  // ---------------------------------------------------------------
  // Tabela de páginas
  // ---------------------------------------------------------------

  /// Gera um novo mapeamento página -> quadro.
  ///
  /// Se [aleatorio] for falso (padrão), a página 0 vai para o quadro
  /// 0, a página 1 para o quadro 1, e assim por diante (mapeamento
  /// sequencial). Se for verdadeiro, os quadros são embaralhados
  /// antes de serem distribuídos. Se houver mais páginas do que
  /// quadros, as páginas excedentes ficam sem quadro (null), como se
  /// ainda não tivessem sido carregadas na memória física.
  void gerarMapeamentoAutomatico({bool aleatorio = false}) {
    final quadrosDisponiveis = List<int>.generate(numFrames, (i) => i);
    if (aleatorio) {
      quadrosDisponiveis.shuffle(Random());
    }

    final novaTabela = List<int?>.filled(numPages, null);
    for (
      var pagina = 0;
      pagina < numPages && pagina < quadrosDisponiveis.length;
      pagina++
    ) {
      novaTabela[pagina] = quadrosDisponiveis[pagina];
    }

    _pageTable = novaTabela;
    notifyListeners();
  }

  /// Define manualmente o quadro associado a uma página.
  ///
  /// Use `quadro = null` para desalocar a página. Se o quadro
  /// informado já estiver associado a outra página, essa outra
  /// página é desalocada automaticamente (para manter o mapeamento
  /// um-para-um entre páginas e quadros).
  void definirQuadro(int pagina, int? quadro) {
    if (pagina < 0 || pagina >= numPages) {
      throw ArgumentError('Página inválida: $pagina');
    }
    if (quadro != null && (quadro < 0 || quadro >= numFrames)) {
      throw ArgumentError('Quadro inválido: $quadro');
    }

    final novaTabela = List<int?>.of(_pageTable);
    if (quadro != null) {
      for (var i = 0; i < novaTabela.length; i++) {
        if (i != pagina && novaTabela[i] == quadro) {
          novaTabela[i] = null;
        }
      }
    }
    novaTabela[pagina] = quadro;
    _pageTable = novaTabela;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Tradução de endereços
  // ---------------------------------------------------------------

  /// Traduz um endereço lógico para um endereço físico, retornando
  /// todos os passos intermediários (página, deslocamento, quadro)
  /// para fins didáticos. Caso o endereço seja inválido ou a página
  /// correspondente não esteja mapeada, o resultado indica a falha.
  TraducaoResultado traduzir(int enderecoLogico) {
    if (enderecoLogico < 0 || enderecoLogico >= logicalMemorySize) {
      return TraducaoResultado.invalido(
        enderecoLogico: enderecoLogico,
        motivo:
            'Endereço fora do espaço de endereçamento lógico '
            '(0 a ${logicalMemorySize - 1}).',
        model: this,
      );
    }

    final pagina = enderecoLogico ~/ pageSize;
    final deslocamento = enderecoLogico % pageSize;
    final quadro = _pageTable[pagina];

    if (quadro == null) {
      return TraducaoResultado.invalido(
        enderecoLogico: enderecoLogico,
        pagina: pagina,
        deslocamento: deslocamento,
        motivo:
            'Falta de página: a página $pagina não está mapeada para '
            'nenhum quadro da memória física (seria uma interceptação '
            'para o sistema operacional).',
        model: this,
      );
    }

    final enderecoFisico = quadro * pageSize + deslocamento;
    return TraducaoResultado.valido(
      enderecoLogico: enderecoLogico,
      pagina: pagina,
      deslocamento: deslocamento,
      quadro: quadro,
      enderecoFisico: enderecoFisico,
      model: this,
    );
  }
}

/// Resultado de uma tradução de endereço lógico -> físico, com todos
/// os passos intermediários necessários para exibição na interface.
class TraducaoResultado {
  final int enderecoLogico;
  final int? pagina;
  final int? deslocamento;
  final int? quadro;
  final int? enderecoFisico;
  final bool sucesso;
  final String? motivoFalha;
  final PagingModel model;

  TraducaoResultado.valido({
    required this.enderecoLogico,
    required this.pagina,
    required this.deslocamento,
    required this.quadro,
    required this.enderecoFisico,
    required this.model,
  }) : sucesso = true,
       motivoFalha = null;

  TraducaoResultado.invalido({
    required this.enderecoLogico,
    this.pagina,
    this.deslocamento,
    required String motivo,
    required this.model,
  }) : sucesso = false,
       motivoFalha = motivo,
       quadro = null,
       enderecoFisico = null;
}
