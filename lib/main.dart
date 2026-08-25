import 'dart:convert';

import 'package:flutter/material.dart';
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

  static Future<List<Movimentacao>> movimentacoes() async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList(movimentacoesKey);

    if (lista == null) return [];

    return lista.map((item) {
      return Movimentacao.fromMap(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarMovimentacoes(
    List<Movimentacao> lista,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      movimentacoesKey,
      lista.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  static Future<List<Produto>> estoque() async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList(estoqueKey);

    if (lista == null) return [];

    return lista.map((item) {
      return Produto.fromMap(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarEstoque(
    List<Produto> lista,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      estoqueKey,
      lista.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  static Future<List<Servico>> servicos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(servicosKey);

    if (dados == null) {
      return [
        const Servico(
          id: 'cilios',
          nome: 'Cílios normal',
          valor: 120,
          icone: Icons.remove_red_eye,
        ),
        const Servico(
          id: 'fox',
          nome: 'Fox',
          valor: 150,
          icone: Icons.auto_awesome,
        ),
        const Servico(
          id: 'sobrancelha',
          nome: 'Sobrancelha',
          valor: 30,
          icone: Icons.face,
        ),
        const Servico(
          id: 'manutencao',
          nome: 'Manutenção',
          valor: 80,
          icone: Icons.build,
        ),
      ];
    }

    final lista = <Servico>[];

    for (final item in dados) {
      final mapa = jsonDecode(item) as Map<String, dynamic>;

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
          id: mapa['id'].toString(),
          nome: mapa['nome'].toString(),
          valor: (mapa['valor'] as num).toDouble(),
          icone: icone,
        ),
      );
    }

    return lista;
  }

  static Future<void> salvarServicos(
    List<Servico> lista,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      servicosKey,
      lista.map((item) {
        return jsonEncode({
          'id': item.id,
          'nome': item.nome,
          'valor': item.valor,
        });
      }).toList(),
    );
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
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
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

  Future<void> registrarGanho(
    String categoria,
    double valor,
  ) async {
    final lista = await Storage.movimentacoes();

    lista.add(
      Movimentacao(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: 'ganho',
        categoria: categoria,
        valor: valor,
        data: dataBanco(dataSelecionada),
      ),
    );

    await Storage.salvarMovimentacoes(lista);

    setState(() {});
  }

  Future<void> adicionarGasto() async {
    final categoria = TextEditingController();
    final valor = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoria,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final valorFinal = valorNumero(valor.text);

                if (categoria.text.trim().isEmpty ||
                    valorFinal <= 0) {
                  return;
                }

                final lista = await Storage.movimentacoes();

                lista.add(
                  Movimentacao(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    tipo: 'gasto',
                    categoria: categoria.text.trim(),
                    valor: valorFinal,
                    data: dataBanco(dataSelecionada),
                  ),
                );

                await Storage.salvarMovimentacoes(lista);

                if (context.mounted) {
                  Navigator.pop(context, true);
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

    if (resultado == true) {
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
      builder: (context) {
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valorFinal = valorNumero(valor.text);

                if (valorFinal > 0) {
                  Navigator.pop(context, valorFinal);
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

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: pagina,
        onDestinationSelected: (index) {
          setState(() {
            pagina = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Estoque',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
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

  final Future<void> Function(String, double) onGanho;
  final Future<void> Function() onGasto;
  final Future<void> Function() onOutroGanho;

  const DashboardPage({
    super.key,
    required this.data,
    required this.onData,
    required this.onGanho,
    required this.onGasto,
    required this.onOutroGanho,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double ganhos = 0;
  double gastos = 0;
  int atendimentos = 0;

  List<Servico> servicos = [];

  Future<void> carregar() async {
    final lista = await Storage.movimentacoes();
    final servicosSalvos = await Storage.servicos();

    final data = dataBanco(widget.data);

    double totalGanhos = 0;
    double totalGastos = 0;
    int totalAtendimentos = 0;

    for (final item in lista) {
      if (item.data != data) continue;

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
      atendimentos = totalAtendimentos;
      servicos = servicosSalvos;
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> editarServico(Servico servico) async {
    final nome = TextEditingController(text: servico.nome);
    final valor = TextEditingController(
      text: servico.valor.toStringAsFixed(2),
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar ${servico.nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(
                  labelText: 'Nome do serviço',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
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

    final novoNome = nome.text.trim();
    final novoValor = valorNumero(valor.text);

    nome.dispose();
    valor.dispose();

    if (novoNome.isEmpty || novoValor <= 0) return;

    final lista = [...servicos];

    final index = lista.indexWhere(
      (item) => item.id == servico.id,
    );

    if (index >= 0) {
      lista[index] = Servico(
        id: servico.id,
        nome: novoNome,
        valor: novoValor,
        icone: servico.icone,
      );
    }

    await Storage.salvarServicos(lista);
    await carregar();
  }

  Future<void> adicionarServico() async {
    final nome = TextEditingController();
    final valor = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo serviço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(
                  labelText: 'Nome do serviço',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Adicionar'),
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

    final nomeFinal = nome.text.trim();
    final valorFinal = valorNumero(valor.text);

    nome.dispose();
    valor.dispose();

    if (nomeFinal.isEmpty || valorFinal <= 0) return;

    final lista = [...servicos];

    lista.add(
      Servico(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nome: nomeFinal,
        valor: valorFinal,
        icone: Icons.auto_awesome,
      ),
    );

    await Storage.salvarServicos(lista);
    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lucro = ganhos - gastos;

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Meu Controle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onData,
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Escolher data',
              ),
            ],
          ),

          Text(
            dataFormatada(dataBanco(widget.data)),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Lucro do dia'),
                  const SizedBox(height: 8),
                  Text(
                    moeda(lucro),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: lucro >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$atendimentos registros hoje'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

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
              const SizedBox(width: 10),
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

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Atendimentos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: adicionarServico,
                icon: const Icon(Icons.add_circle),
                tooltip: 'Adicionar serviço',
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...servicos.map(
            (servico) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(servico.icone),
                ),
                title: Text(
                  servico.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  moeda(servico.valor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => editarServico(servico),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar valor',
                    ),
                    const Icon(Icons.add_circle),
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

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () async {
              await widget.onOutroGanho();
              await carregar();
            },
            icon: const Icon(Icons.add),
            label: const Text('Outro ganho'),
          ),

          const SizedBox(height: 10),

          FilledButton.icon(
            onPressed: () async {
              await widget.onGasto();
              await carregar();
            },
            icon: const Icon(Icons.remove_circle),
            label: const Text('Adicionar gasto'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor),
            const SizedBox(height: 5),
            Text(titulo),
            Text(
              moeda(valor),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  List<Produto> produtos = [];
  String busca = '';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final lista = await Storage.estoque();

    if (!mounted) return;

    setState(() {
      produtos = lista;
    });
  }

  Future<void> editarProduto([Produto? produto]) async {
    final nome = TextEditingController(
      text: produto?.nome ?? '',
    );

    final quantidade = TextEditingController(
      text: produto?.quantidade.toString() ?? '0',
    );

    final minimo = TextEditingController(
      text: produto?.estoqueMinimo.toString() ?? '0',
    );

    final compra = TextEditingController(
      text: produto?.precoCompra.toStringAsFixed(2) ?? '',
    );

    final venda = TextEditingController(
      text: produto?.precoVenda.toStringAsFixed(2) ?? '',
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            produto == null
                ? 'Adicionar produto'
                : 'Editar produto',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(
                    labelText: 'Nome do produto',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantidade,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minimo,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: compra,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço de compra',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: venda,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço de venda',
                    prefixText: 'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
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

    final nomeFinal = nome.text.trim();
    final quantidadeFinal = int.tryParse(
          quantidade.text.trim(),
        ) ??
        0;

    final minimoFinal = int.tryParse(
          minimo.text.trim(),
        ) ??
        0;

    final compraFinal = valorNumero(compra.text);
    final vendaFinal = valorNumero(venda.text);

    nome.dispose();
    quantidade.dispose();
    minimo.dispose();
    compra.dispose();
    venda.dispose();

    if (nomeFinal.isEmpty) return;

    final lista = [...produtos];

    final novo = Produto(
      id: produto?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      nome: nomeFinal,
      quantidade: quantidadeFinal,
      estoqueMinimo: minimoFinal,
      precoCompra: compraFinal,
      precoVenda: vendaFinal,
    );

    if (produto == null) {
      lista.add(novo);
    } else {
      final index = lista.indexWhere(
        (item) => item.id == produto.id,
      );

      if (index >= 0) {
        lista[index] = novo;
      }
    }

    await Storage.salvarEstoque(lista);
    await carregar();
  }

  Future<void> excluirProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir produto?'),
          content: Text(
            'Deseja excluir "${produto.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    produtos.removeWhere(
      (item) => item.id == produto.id,
    );

    await Storage.salvarEstoque(produtos);
    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = produtos.where((produto) {
      if (busca.trim().isEmpty) return true;

      return produto.nome.toLowerCase().contains(
            busca.toLowerCase(),
          );
    }).toList();

    final valorTotal = produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorEstoque,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editarProduto(),
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Estoque',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${produtos.length} produtos • ${moeda(valorTotal)}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            onChanged: (texto) {
              setState(() {
                busca = texto;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar produto...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (lista.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
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
                leading: CircleAvatar(
                  child: Text(
                    produto.quantidade.toString(),
                  ),
                ),
                title: Text(
                  produto.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Quantidade: ${produto.quantidade}\n'
                  'Compra: ${moeda(produto.precoCompra)}\n'
                  'Venda: ${moeda(produto.precoVenda)}\n'
                  'Lucro/un.: ${moeda(produto.lucroUnitario)}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (opcao) {
                    if (opcao == 'editar') {
                      editarProduto(produto);
                    }

                    if (opcao == 'excluir') {
                      excluirProduto(produto);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 10),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 10),
                          Text('Excluir'),
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
    );
  }
}

// ============================================================
// HISTÓRICO
// ============================================================

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<Movimentacao> lista = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final dados = await Storage.movimentacoes();

    if (!mounted) return;

    setState(() {
      lista = dados.reversed.toList();
    });
  }

  Future<void> excluir(Movimentacao item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir registro?'),
          content: Text(
            'Deseja excluir "${item.categoria}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final todos = await Storage.movimentacoes();

    todos.removeWhere(
      (movimentacao) => movimentacao.id == item.id,
    );

    await Storage.salvarMovimentacoes(todos);
    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (lista.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
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
                leading: CircleAvatar(
                  child: Icon(
                    item.tipo == 'ganho'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                ),
                title: Text(
                  item.categoria,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  dataFormatada(item.data),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.tipo == 'ganho' ? '+' : '-'} '
                      '${moeda(item.valor)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.tipo == 'ganho'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () => excluir(item),
                      icon: const Icon(Icons.delete_outline),
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
