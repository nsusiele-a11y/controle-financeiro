import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuControleApp());
}

// ============================================================
// FUNÇÕES AUXILIARES
// ============================================================

String moeda(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

String dataBanco(DateTime data) {
  return '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}

String dataFormatada(String data) {
  final partes = data.split('-');

  if (partes.length == 3) {
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  return data;
}

double valorNumero(String texto) {
  String valor = texto.trim();

  if (valor.isEmpty) return 0;

  valor = valor.replaceAll('R\$', '').replaceAll(' ', '');

  if (valor.contains(',') && valor.contains('.')) {
    valor = valor.replaceAll('.', '').replaceAll(',', '.');
  } else {
    valor = valor.replaceAll(',', '.');
  }

  return double.tryParse(valor) ?? 0;
}

// ============================================================
// MODELO DE MOVIMENTAÇÃO
// ============================================================

class Movimentacao {
  final String id;
  final String tipo;
  final String categoria;
  final double valor;
  final String data;

  Movimentacao({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'categoria': categoria,
      'valor': valor,
      'data': data,
    };
  }

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: map['id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'gasto',
      categoria: map['categoria']?.toString() ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      data: map['data']?.toString() ?? '',
    );
  }
}

// ============================================================
// MODELO DE PRODUTO
// ============================================================

class Produto {
  final String id;
  final String nome;
  final int quantidade;
  final int estoqueMinimo;
  final double precoCompra;
  final double precoVenda;

  Produto({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.estoqueMinimo,
    required this.precoCompra,
    required this.precoVenda,
  });

  double get valorEstoque => quantidade * precoCompra;

  double get lucroUnitario => precoVenda - precoCompra;

  bool get estoqueBaixo => quantidade <= estoqueMinimo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'estoqueMinimo': estoqueMinimo,
      'precoCompra': precoCompra,
      'precoVenda': precoVenda,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
      estoqueMinimo: (map['estoqueMinimo'] as num?)?.toInt() ?? 0,
      precoCompra: (map['precoCompra'] as num?)?.toDouble() ?? 0,
      precoVenda: (map['precoVenda'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// MODELO DE SERVIÇO
// ============================================================

class Servico {
  final String id;
  final String nome;
  final double valor;
  final IconData icone;

  const Servico({
    required this.id,
    required this.nome,
    required this.valor,
    required this.icone,
  });
}

// ============================================================
// ARMAZENAMENTO
// ============================================================

class Storage {
  static const String movimentacoesKey = 'movimentacoes';
  static const String estoqueKey = 'estoque';
  static const String servicosKey = 'servicos';

  static const String backupVersion = '1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<Movimentacao>> movimentacoes() async {
    try {
      final prefs = await _getPrefs();
      final lista = prefs.getStringList(movimentacoesKey);

      if (lista == null) return [];

      final resultado = <Movimentacao>[];

      for (final item in lista) {
        try {
          final decoded = jsonDecode(item);

          if (decoded is Map<String, dynamic>) {
            final movimentacao =
                Movimentacao.fromMap(decoded);

            if (movimentacao.id.isNotEmpty) {
              resultado.add(movimentacao);
            }
          }
        } catch (_) {}
      }

      return resultado;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> salvarMovimentacoes(
    List<Movimentacao> lista,
  ) async {
    try {
      final prefs = await _getPrefs();

      return await prefs.setStringList(
        movimentacoesKey,
        lista.map((item) => jsonEncode(item.toMap())).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<List<Produto>> estoque() async {
    try {
      final prefs = await _getPrefs();
      final lista = prefs.getStringList(estoqueKey);

      if (lista == null) return [];

      final resultado = <Produto>[];

      for (final item in lista) {
        try {
          final decoded = jsonDecode(item);

          if (decoded is Map<String, dynamic>) {
            final produto = Produto.fromMap(decoded);

            if (produto.id.isNotEmpty) {
              resultado.add(produto);
            }
          }
        } catch (_) {}
      }

      return resultado;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> salvarEstoque(
    List<Produto> lista,
  ) async {
    try {
      final prefs = await _getPrefs();

      return await prefs.setStringList(
        estoqueKey,
        lista.map((item) => jsonEncode(item.toMap())).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  static List<Servico> servicosPadrao() {
    return const [
      Servico(
        id: 'cilios',
        nome: 'Cílios normal',
        valor: 120,
        icone: Icons.remove_red_eye,
      ),
      Servico(
        id: 'fox',
        nome: 'Fox',
        valor: 150,
        icone: Icons.auto_awesome,
      ),
      Servico(
        id: 'sobrancelha',
        nome: 'Sobrancelha',
        valor: 30,
        icone: Icons.face,
      ),
      Servico(
        id: 'manutencao',
        nome: 'Manutenção',
        valor: 80,
        icone: Icons.build,
      ),
    ];
  }

  static Future<List<Servico>> servicos() async {
    try {
      final prefs = await _getPrefs();
      final dados = prefs.getStringList(servicosKey);

      if (dados == null) {
        return servicosPadrao();
      }

      final lista = <Servico>[];

      for (final item in dados) {
        try {
          final mapa = jsonDecode(item);

          if (mapa is! Map<String, dynamic>) {
            continue;
          }

          IconData icone = Icons.auto_awesome;

          switch (mapa['id']) {
            case 'cilios':
              icone = Icons.remove_red_eye;
              break;
            case 'fox':
              icone = Icons.auto_awesome;
              break;
            case 'sobrancelha':
              icone = Icons.face;
              break;
            case 'manutencao':
              icone = Icons.build;
              break;
          }

          lista.add(
            Servico(
              id: mapa['id']?.toString() ?? '',
              nome: mapa['nome']?.toString() ?? '',
              valor: (mapa['valor'] as num?)?.toDouble() ?? 0,
              icone: icone,
            ),
          );
        } catch (_) {}
      }

      return lista.isEmpty ? servicosPadrao() : lista;
    } catch (_) {
      return servicosPadrao();
    }
  }

  static Future<bool> salvarServicos(
    List<Servico> lista,
  ) async {
    try {
      final prefs = await _getPrefs();

      return await prefs.setStringList(
        servicosKey,
        lista.map((item) {
          return jsonEncode({
            'id': item.id,
            'nome': item.nome,
            'valor': item.valor,
          });
        }).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // BACKUP
  // ==========================================================

  static Future<String> criarBackup() async {
    final movimentacoesLista = await movimentacoes();
    final estoqueLista = await estoque();
    final servicosLista = await servicos();

    final backup = {
      'app': 'Meu Controle',
      'versaoBackup': backupVersion,
      'dataBackup': DateTime.now().toIso8601String(),
      'movimentacoes':
          movimentacoesLista.map((item) => item.toMap()).toList(),
      'estoque':
          estoqueLista.map((item) => item.toMap()).toList(),
      'servicos': servicosLista.map((item) {
        return {
          'id': item.id,
          'nome': item.nome,
          'valor': item.valor,
        };
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<bool> restaurarBackup(String texto) async {
    try {
      final decoded = jsonDecode(texto);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      if (decoded['app'] != 'Meu Controle') {
        return false;
      }

      final movimentacoesDados = decoded['movimentacoes'];
      final estoqueDados = decoded['estoque'];
      final servicosDados = decoded['servicos'];

      if (movimentacoesDados is! List ||
          estoqueDados is! List ||
          servicosDados is! List) {
        return false;
      }

      final novasMovimentacoes = <Movimentacao>[];

      for (final item in movimentacoesDados) {
        if (item is Map<String, dynamic>) {
          novasMovimentacoes.add(
            Movimentacao.fromMap(item),
          );
        }
      }

      final novoEstoque = <Produto>[];

      for (final item in estoqueDados) {
        if (item is Map<String, dynamic>) {
          novoEstoque.add(
            Produto.fromMap(item),
          );
        }
      }

      final novosServicos = <Servico>[];

      for (final item in servicosDados) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        IconData icone = Icons.auto_awesome;

        switch (item['id']) {
          case 'cilios':
            icone = Icons.remove_red_eye;
            break;
          case 'fox':
            icone = Icons.auto_awesome;
            break;
          case 'sobrancelha':
            icone = Icons.face;
            break;
          case 'manutencao':
            icone = Icons.build;
            break;
        }

        novosServicos.add(
          Servico(
            id: item['id']?.toString() ?? '',
            nome: item['nome']?.toString() ?? '',
            valor: (item['valor'] as num?)?.toDouble() ?? 0,
            icone: icone,
          ),
        );
      }

      final salvouMovimentacoes =
          await salvarMovimentacoes(novasMovimentacoes);

      final salvouEstoque =
          await salvarEstoque(novoEstoque);

      final salvouServicos =
          await salvarServicos(novosServicos);

      return salvouMovimentacoes &&
          salvouEstoque &&
          salvouServicos;
    } catch (_) {
      return false;
    }
  }
}

// ============================================================
// APP
// ============================================================

class MeuControleApp extends StatelessWidget {
  const MeuControleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Controle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF5F7F6),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pagina = 0;

  DateTime dataSelecionada = DateTime.now();

  Future<void> mostrarMensagem(
    String mensagem,
  ) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> registrarGanho(
    String categoria,
    double valor,
  ) async {
    final lista = await Storage.movimentacoes();

    lista.add(
      Movimentacao(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        tipo: 'ganho',
        categoria: categoria,
        valor: valor,
        data: dataBanco(dataSelecionada),
      ),
    );

    final salvou =
        await Storage.salvarMovimentacoes(lista);

    if (!salvou) {
      await mostrarMensagem(
        'Não foi possível salvar o ganho.',
      );
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> adicionarGasto() async {
    final categoria = TextEditingController();
    final valor = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoria,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon:
                      Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valor,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final valorFinal =
                    valorNumero(valor.text);

                if (categoria.text.trim().isEmpty ||
                    valorFinal <= 0) {
                  return;
                }

                final lista =
                    await Storage.movimentacoes();

                lista.add(
                  Movimentacao(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    tipo: 'gasto',
                    categoria:
                        categoria.text.trim(),
                    valor: valorFinal,
                    data: dataBanco(
                      dataSelecionada,
                    ),
                  ),
                );

                final salvou =
                    await Storage.salvarMovimentacoes(
                  lista,
                );

                if (!salvou) return;

                if (dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    categoria.dispose();
    valor.dispose();

    if (resultado == true && mounted) {
      setState(() {});
    }
  }

  Future<void> outroGanho() async {
    final categoria = TextEditingController(
      text: 'Outro ganho',
    );

    final valor = TextEditingController();

    final resultado = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Outro ganho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoria,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valor,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valorFinal =
                    valorNumero(valor.text);

                if (valorFinal > 0) {
                  Navigator.pop(
                    dialogContext,
                    valorFinal,
                  );
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    final nome = categoria.text.trim();

    categoria.dispose();
    valor.dispose();

    if (resultado != null) {
      await registrarGanho(
        nome.isEmpty ? 'Outro ganho' : nome,
        resultado,
      );
    }
  }

  Future<void> escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null && mounted) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

  // ==========================================================
  // SALVAR AGORA
  // ==========================================================

  Future<void> salvarAgora() async {
    final movimentacoes =
        await Storage.movimentacoes();

    final estoque =
        await Storage.estoque();

    final servicos =
        await Storage.servicos();

    final a =
        await Storage.salvarMovimentacoes(
      movimentacoes,
    );

    final b =
        await Storage.salvarEstoque(
      estoque,
    );

    final c =
        await Storage.salvarServicos(
      servicos,
    );

    if (!mounted) return;

    await mostrarMensagem(
      a && b && c
          ? 'Dados salvos com sucesso.'
          : 'Não foi possível salvar todos os dados.',
    );
  }

  // ==========================================================
  // EXPORTAR BACKUP
  // ==========================================================

  Future<void> exportarBackup() async {
    final backup =
        await Storage.criarBackup();

    if (!mounted) return;

    final controller =
        TextEditingController(
      text: backup,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Exportar backup'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Copie o código abaixo e guarde em um local seguro.',
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller: controller,
                    readOnly: true,
                    maxLines: 12,
                    style:
                        const TextStyle(
                      fontSize: 11,
                    ),
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Fechar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: controller.text,
                  ),
                );

                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Backup copiado.',
                    ),
                  ),
                );
              },
              icon:
                  const Icon(Icons.copy),
              label:
                  const Text('Copiar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // ==========================================================
  // RESTAURAR BACKUP
  // ==========================================================

  Future<void> restaurarBackup() async {
    final controller =
        TextEditingController();

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Restaurar backup'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Cole abaixo o código do backup.',
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller: controller,
                    maxLines: 12,
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                      hintText:
                          'Cole o backup aqui',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (controller.text
                    .trim()
                    .isEmpty) {
                  return;
                }

                final sucesso =
                    await Storage
                        .restaurarBackup(
                  controller.text.trim(),
                );

                if (!dialogContext.mounted) {
                  return;
                }

                if (sucesso) {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                } else {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Backup inválido ou corrompido.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.restore,
              ),
              label:
                  const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (resultado == true && mounted) {
      setState(() {});

      await mostrarMensagem(
        'Backup restaurado com sucesso.',
      );
    }
  }

  // ==========================================================
  // MENU DE DADOS
  // ==========================================================

  Future<void> abrirMenuDados() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Dados e backup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                ListTile(
                  leading:
                      const Icon(
                    Icons.save,
                  ),
                  title:
                      const Text(
                    'Salvar agora',
                  ),
                  subtitle:
                      const Text(
                    'Salvar todos os dados atuais',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );
                    await salvarAgora();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(
                    Icons.file_upload_outlined,
                  ),
                  title:
                      const Text(
                    'Exportar backup',
                  ),
                  subtitle:
                      const Text(
                    'Copiar uma cópia completa dos dados',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );
                    await exportarBackup();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(
                    Icons.restore,
                  ),
                  title:
                      const Text(
                    'Restaurar backup',
                  ),
                  subtitle:
                      const Text(
                    'Recuperar dados de um backup',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );
                    await restaurarBackup();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      DashboardPage(
        data: dataSelecionada,
        onData: escolherData,
        onGanho: registrarGanho,
        onGasto: adicionarGasto,
        onOutroGanho: outroGanho,
      ),
      const EstoquePage(),
      const HistoricoPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: paginas[pagina],
      ),
      floatingActionButton:
          FloatingActionButton.small(
        onPressed: abrirMenuDados,
        child: const Icon(
          Icons.save_outlined,
        ),
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: pagina,
        onDestinationSelected:
            (index) {
          setState(() {
            pagina = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.inventory_2_outlined,
            ),
            selectedIcon: Icon(
              Icons.inventory_2,
            ),
            label: 'Estoque',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history,
            ),
            selectedIcon: Icon(
              Icons.history,
            ),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatefulWidget {
  final DateTime data;
  final VoidCallback onData;

  final Future<void> Function(
    String,
    double,
  ) onGanho;

  final Future<void> Function()
      onGasto;

  final Future<void> Function()
      onOutroGanho;

  const DashboardPage({
    super.key,
    required this.data,
    required this.onData,
    required this.onGanho,
    required this.onGasto,
    required this.onOutroGanho,
  });

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  double ganhos = 0;
  double gastos = 0;
  int atendimentos = 0;

  List<Servico> servicos = [];

  Future<void> carregar() async {
    final lista =
        await Storage.movimentacoes();

    final servicosSalvos =
        await Storage.servicos();

    final data =
        dataBanco(widget.data);

    double totalGanhos = 0;
    double totalGastos = 0;
    int totalAtendimentos = 0;

    for (final item in lista) {
      if (item.data != data) {
        continue;
      }

      if (item.tipo == 'ganho') {
        totalGanhos += item.valor;
        totalAtendimentos++;
      } else {
        totalGastos += item.valor;
      }
    }

    if (!mounted) return;

    setState(() {
      ganhos = totalGanhos;
      gastos = totalGastos;
      atendimentos =
          totalAtendimentos;
      servicos = servicosSalvos;
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> editarServico(
    Servico servico,
  ) async {
    final nome =
        TextEditingController(
      text: servico.nome,
    );

    final valor =
        TextEditingController(
      text: servico.valor
          .toStringAsFixed(2),
    );

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Editar ${servico.nome}',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nome do serviço',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: valor,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      nome.dispose();
      valor.dispose();
      return;
    }

    final novoNome =
        nome.text.trim();

    final novoValor =
        valorNumero(valor.text);

    nome.dispose();
    valor.dispose();

    if (novoNome.isEmpty ||
        novoValor <= 0) {
      return;
    }

    final lista = [...servicos];

    final index =
        lista.indexWhere(
      (item) =>
          item.id == servico.id,
    );

    if (index >= 0) {
      lista[index] = Servico(
        id: servico.id,
        nome: novoNome,
        valor: novoValor,
        icone: servico.icone,
      );
    }

    await Storage.salvarServicos(
      lista,
    );

    await carregar();
  }

  Future<void> adicionarServico() async {
    final nome =
        TextEditingController();

    final valor =
        TextEditingController();

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Novo serviço'),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nome do serviço',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: valor,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      nome.dispose();
      valor.dispose();
      return;
    }

    final nomeFinal =
        nome.text.trim();

    final valorFinal =
        valorNumero(valor.text);

    nome.dispose();
    valor.dispose();

    if (nomeFinal.isEmpty ||
        valorFinal <= 0) {
      return;
    }

    final lista = [...servicos];

    lista.add(
      Servico(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        nome: nomeFinal,
        valor: valorFinal,
        icone:
            Icons.auto_awesome,
      ),
    );

    await Storage.salvarServicos(
      lista,
    );

    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lucro = ganhos - gastos;

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Meu Controle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    widget.onData,
                icon:
                    const Icon(
                  Icons.calendar_month,
                ),
                tooltip:
                    'Escolher data',
              ),
            ],
          ),
          Text(
            dataFormatada(
              dataBanco(widget.data),
            ),
            style:
                const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Lucro do dia',
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    moeda(lucro),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                      color: lucro >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '$atendimentos registros hoje',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              Expanded(
                child: _resumo(
                  'Ganhos',
                  ganhos,
                  Colors.green,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _resumo(
                  'Gastos',
                  gastos,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Atendimentos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    adicionarServico,
                icon:
                    const Icon(
                  Icons.add_circle,
                ),
                tooltip:
                    'Adicionar serviço',
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          ...servicos.map(
            (servico) => Card(
              child: ListTile(
                leading:
                    CircleAvatar(
                  child: Icon(
                    servico.icone,
                  ),
                ),
                title: Text(
                  servico.nome,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  moeda(
                    servico.valor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          editarServico(
                        servico,
                      ),
                      icon:
                          const Icon(
                        Icons.edit,
                      ),
                      tooltip:
                          'Editar valor',
                    ),
                    const Icon(
                      Icons.add_circle,
                    ),
                  ],
                ),
                onTap: () async {
                  await widget.onGanho(
                    servico.nome,
                    servico.valor,
                  );

                  await carregar();
                },
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await widget
                  .onOutroGanho();

              await carregar();
            },
            icon:
                const Icon(Icons.add),
            label:
                const Text('Outro ganho'),
          ),
          const SizedBox(
            height: 10,
          ),
          FilledButton.icon(
            onPressed: () async {
              await widget.onGasto();

              await carregar();
            },
            icon:
                const Icon(
              Icons.remove_circle,
            ),
            label:
                const Text(
              'Adicionar gasto',
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final movimentacoes =
                  await Storage
                      .movimentacoes();

              final estoque =
                  await Storage.estoque();

              final servicos =
                  await Storage.servicos();

              final a =
                  await Storage
                      .salvarMovimentacoes(
                movimentacoes,
              );

              final b =
                  await Storage
                      .salvarEstoque(
                estoque,
              );

              final c =
                  await Storage
                      .salvarServicos(
                servicos,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    a && b && c
                        ? 'Tudo salvo com sucesso.'
                        : 'Houve um problema ao salvar.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.save_outlined,
            ),
            label:
                const Text('Salvar agora'),
          ),
        ],
      ),
    );
  }

  Widget _resumo(
    String titulo,
    double valor,
    Color cor,
    IconData icone,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icone,
              color: cor,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(titulo),
            Text(
              moeda(valor),
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ESTOQUE
// ============================================================

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() =>
      _EstoquePageState();
}

class _EstoquePageState
    extends State<EstoquePage> {
  List<Produto> produtos = [];

  String busca = '';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final lista =
        await Storage.estoque();

    if (!mounted) return;

    setState(() {
      produtos = lista;
    });
  }

  Future<void> editarProduto(
    [Produto? produto],
  ) async {
    final nome =
        TextEditingController(
      text: produto?.nome ?? '',
    );

    final quantidade =
        TextEditingController(
      text: produto?.quantidade
              .toString() ??
          '0',
    );

    final minimo =
        TextEditingController(
      text: produto?.estoqueMinimo
              .toString() ??
          '0',
    );

    final compra =
        TextEditingController(
      text: produto?.precoCompra
              .toStringAsFixed(2) ??
          '',
    );

    final venda =
        TextEditingController(
      text: produto?.precoVenda
              .toStringAsFixed(2) ??
          '',
    );

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            produto == null
                ? 'Adicionar produto'
                : 'Editar produto',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  autofocus: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nome do produto',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller:
                      quantidade,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Quantidade',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: minimo,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Estoque mínimo',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: compra,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Preço de compra',
                    prefixText:
                        'R\$ ',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: venda,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Preço de venda',
                    prefixText:
                        'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      nome.dispose();
      quantidade.dispose();
      minimo.dispose();
      compra.dispose();
      venda.dispose();
      return;
    }

    final nomeFinal =
        nome.text.trim();

    final quantidadeFinal =
        int.tryParse(
              quantidade.text.trim(),
            ) ??
            0;

    final minimoFinal =
        int.tryParse(
              minimo.text.trim(),
            ) ??
            0;

    final compraFinal =
        valorNumero(compra.text);

    final vendaFinal =
        valorNumero(venda.text);

    nome.dispose();
    quantidade.dispose();
    minimo.dispose();
    compra.dispose();
    venda.dispose();

    if (nomeFinal.isEmpty) return;

    final lista = [...produtos];

    final novo = Produto(
      id: produto?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
      nome: nomeFinal,
      quantidade:
          quantidadeFinal < 0
              ? 0
              : quantidadeFinal,
      estoqueMinimo:
          minimoFinal < 0
              ? 0
              : minimoFinal,
      precoCompra:
          compraFinal < 0
              ? 0
              : compraFinal,
      precoVenda:
          vendaFinal < 0
              ? 0
              : vendaFinal,
    );

    if (produto == null) {
      lista.add(novo);
    } else {
      final index =
          lista.indexWhere(
        (item) =>
            item.id == produto.id,
      );

      if (index >= 0) {
        lista[index] = novo;
      }
    }

    await Storage.salvarEstoque(
      lista,
    );

    await carregar();
  }

  Future<void> excluirProduto(
    Produto produto,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Excluir produto?'),
          content: Text(
            'Deseja excluir "${produto.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    produtos.removeWhere(
      (item) =>
          item.id == produto.id,
    );

    await Storage.salvarEstoque(
      produtos,
    );

    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lista =
        produtos.where((produto) {
      if (busca.trim().isEmpty) {
        return true;
      }

      return produto.nome
          .toLowerCase()
          .contains(
            busca.toLowerCase(),
          );
    }).toList();

    final valorTotal =
        produtos.fold<double>(
      0,
      (total, produto) =>
          total + produto.valorEstoque,
    );

    return Scaffold(
      backgroundColor:
          Colors.transparent,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            () => editarProduto(),
        icon: const Icon(Icons.add),
        label:
            const Text('Produto'),
      ),
      body: RefreshIndicator(
        onRefresh: carregar,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            const Text(
              'Estoque',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              '${produtos.length} produtos • ${moeda(valorTotal)}',
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              onChanged: (texto) {
                setState(() {
                  busca = texto;
                });
              },
              decoration:
                  InputDecoration(
                hintText:
                    'Buscar produto...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(14),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            if (lista.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhum produto cadastrado.',
                    ),
                  ),
                ),
              ),
            ...lista.map(
              (produto) => Card(
                child: ListTile(
                  leading:
                      CircleAvatar(
                    child: Text(
                      produto
                          .quantidade
                          .toString(),
                    ),
                  ),
                  title: Text(
                    produto.nome,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  subtitle: Text(
                    'Quantidade: ${produto.quantidade}\n'
                    'Compra: ${moeda(produto.precoCompra)}\n'
                    'Venda: ${moeda(produto.precoVenda)}\n'
                    'Lucro/un.: ${moeda(produto.lucroUnitario)}',
                  ),
                  isThreeLine: true,
                  trailing:
                      PopupMenuButton<
                          String>(
                    onSelected:
                        (opcao) {
                      if (opcao ==
                          'editar') {
                        editarProduto(
                          produto,
                        );
                      }

                      if (opcao ==
                          'excluir') {
                        excluirProduto(
                          produto,
                        );
                      }
                    },
                    itemBuilder:
                        (context) =>
                            const [
                      PopupMenuItem(
                        value:
                            'editar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Editar',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value:
                            'excluir',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Excluir',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTÓRICO
// ============================================================

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() =>
      _HistoricoPageState();
}

class _HistoricoPageState
    extends State<HistoricoPage> {
  List<Movimentacao> lista = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final dados =
        await Storage.movimentacoes();

    if (!mounted) return;

    setState(() {
      lista =
          dados.reversed.toList();
    });
  }

  Future<void> excluir(
    Movimentacao item,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Excluir registro?'),
          content: Text(
            'Deseja excluir "${item.categoria}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final todos =
        await Storage.movimentacoes();

    todos.removeWhere(
      (movimentacao) =>
          movimentacao.id ==
          item.id,
    );

    await Storage.salvarMovimentacoes(
      todos,
    );

    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          if (lista.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nenhum registro encontrado.',
                  ),
                ),
              ),
            ),
          ...lista.map(
            (item) => Card(
              child: ListTile(
                leading:
                    CircleAvatar(
                  child: Icon(
                    item.tipo ==
                            'ganho'
                        ? Icons
                            .arrow_upward
                        : Icons
                            .arrow_downward,
                  ),
                ),
                title: Text(
                  item.categoria,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
                subtitle: Text(
                  dataFormatada(
                    item.data,
                  ),
                ),
                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      '${item.tipo == 'ganho' ? '+' : '-'} '
                      '${moeda(item.valor)}',
                      style: TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        color: item.tipo ==
                                'ganho'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => excluir(
                        item,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .delete_outline,
                      ),
                      tooltip:
                          'Excluir',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
