import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const ControleFinanceiroApp());
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Controle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// BANCO DE DADOS
// ============================================================

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();

    final path = p.join(
      databasePath,
      'controle_financeiro.db',
    );

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _criarTabelas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS estoque (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome TEXT NOT NULL,
              quantidade INTEGER NOT NULL,
              precoCompra REAL NOT NULL,
              precoVenda REAL NOT NULL
            )
          ''');
        }
      },
    );

    return _database!;
  }

  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE movimentacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE estoque (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        precoCompra REAL NOT NULL,
        precoVenda REAL NOT NULL
      )
    ''');
  }

  Future<int> adicionarMovimentacao({
    required String tipo,
    required String categoria,
    required double valor,
    required String data,
  }) async {
    final db = await database;

    return db.insert(
      'movimentacoes',
      {
        'tipo': tipo,
        'categoria': categoria,
        'valor': valor,
        'data': data,
      },
    );
  }

  Future<List<Map<String, dynamic>>> buscarMovimentacoes({
    String? data,
  }) async {
    final db = await database;

    return db.query(
      'movimentacoes',
      where: data == null ? null : 'data = ?',
      whereArgs: data == null ? null : [data],
      orderBy: 'data DESC, id DESC',
    );
  }

  Future<int> excluirMovimentacao(int id) async {
    final db = await database;

    return db.delete(
      'movimentacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- ESTOQUE ----------------

  Future<List<Map<String, dynamic>>> buscarEstoque() async {
    final db = await database;

    return db.query(
      'estoque',
      orderBy: 'nome ASC',
    );
  }

  Future<int> adicionarEstoque({
    required String nome,
    required int quantidade,
    required double precoCompra,
    required double precoVenda,
  }) async {
    final db = await database;

    return db.insert(
      'estoque',
      {
        'nome': nome,
        'quantidade': quantidade,
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
      },
    );
  }

  Future<int> atualizarEstoque({
    required int id,
    required String nome,
    required int quantidade,
    required double precoCompra,
    required double precoVenda,
  }) async {
    final db = await database;

    return db.update(
      'estoque',
      {
        'nome': nome,
        'quantidade': quantidade,
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> excluirEstoque(int id) async {
    final db = await database;

    return db.delete(
      'estoque',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> diminuirEstoque(
    int id,
    int quantidade,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'estoque',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (resultado.isEmpty) return;

    final atual =
        (resultado.first['quantidade'] as num).toInt();

    final novaQuantidade =
        (atual - quantidade).clamp(0, 999999);

    await db.update(
      'estoque',
      {
        'quantidade': novaQuantidade,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ============================================================
// FUNÇÕES
// ============================================================

final moeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final formatoData = DateFormat('dd/MM/yyyy');

final formatoBanco = DateFormat('yyyy-MM-dd');

double converterValor(String valor) {
  return double.tryParse(
        valor
            .replaceAll('.', '')
            .replaceAll(',', '.'),
      ) ??
      0;
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

  final servicos = const [
    {
      'nome': 'Cílios normal',
      'valor': 120.0,
      'icone': Icons.remove_red_eye,
    },
    {
      'nome': 'Fox',
      'valor': 150.0,
      'icone': Icons.auto_awesome,
    },
    {
      'nome': 'Sobrancelha',
      'valor': 30.0,
      'icone': Icons.face,
    },
    {
      'nome': 'Manutenção',
      'valor': 80.0,
      'icone': Icons.build,
    },
  ];

  Future<void> registrarServico(
    String nome,
    double valor,
  ) async {
    await DatabaseHelper.instance.adicionarMovimentacao(
      tipo: 'ganho',
      categoria: nome,
      valor: valor,
      data: formatoBanco.format(dataSelecionada),
    );

    setState(() {});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$nome registrado: ${moeda.format(valor)}',
        ),
      ),
    );
  }

  Future<void> outroGanho() async {
    final controller = TextEditingController();

    final valor = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Outro ganho'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valor =
                    converterValor(controller.text);

                if (valor > 0) {
                  Navigator.pop(context, valor);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (valor == null) return;

    await DatabaseHelper.instance.adicionarMovimentacao(
      tipo: 'ganho',
      categoria: 'Outro ganho',
      valor: valor,
      data: formatoBanco.format(dataSelecionada),
    );

    setState(() {});
  }

  Future<void> adicionarGasto() async {
    final categoriaController =
        TextEditingController();

    final valorController =
        TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'Ex.: Material',
                ),
              ),
              TextField(
                controller: valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(
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
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final categoria =
                    categoriaController.text.trim();

                final valor =
                    converterValor(valorController.text);

                if (categoria.isEmpty || valor <= 0) {
                  return;
                }

                await DatabaseHelper.instance
                    .adicionarMovimentacao(
                  tipo: 'gasto',
                  categoria: categoria,
                  valor: valor,
                  data:
                      formatoBanco.format(dataSelecionada),
                );

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

    categoriaController.dispose();
    valorController.dispose();

    if (resultado == true) {
      setState(() {});
    }
  }

  Future<void> selecionarData() async {
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
        servicos: servicos,
        selecionarData: selecionarData,
        registrarServico: registrarServico,
        outroGanho: outroGanho,
        adicionarGasto: adicionarGasto,
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

  final List<Map<String, Object>> servicos;

  final VoidCallback selecionarData;

  final Future<void> Function(
    String,
    double,
  ) registrarServico;

  final Future<void> Function() outroGanho;

  final Future<void> Function() adicionarGasto;

  const DashboardPage({
    super.key,
    required this.data,
    required this.servicos,
    required this.selecionarData,
    required this.registrarServico,
    required this.outroGanho,
    required this.adicionarGasto,
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

  Future<void> carregar() async {
    final registros =
        await DatabaseHelper.instance.buscarMovimentacoes(
      data: formatoBanco.format(widget.data),
    );

    double novosGanhos = 0;
    double novosGastos = 0;

    for (final registro in registros) {
      final valor =
          (registro['valor'] as num).toDouble();

      if (registro['tipo'] == 'ganho') {
        novosGanhos += valor;
      } else {
        novosGastos += valor;
      }
    }

    if (!mounted) return;

    setState(() {
      ganhos = novosGanhos;
      gastos = novosGastos;

      atendimentos = registros
          .where(
            (registro) =>
                registro['tipo'] == 'ganho',
          )
          .length;
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void didUpdateWidget(
    covariant DashboardPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    carregar();
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
                onPressed: widget.selecionarData,
                icon: const Icon(
                  Icons.calendar_month,
                ),
              ),
            ],
          ),

          Text(
            formatoData.format(widget.data),
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
                  const Text(
                    'Lucro do dia',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moeda.format(lucro),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: lucro >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$atendimentos ganhos registrados',
                  ),
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
                  Icons.arrow_upward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resumo(
                  'Gastos',
                  gastos,
                  Icons.arrow_downward,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Registrar atendimento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ...widget.servicos.map(
            (servico) {
              final nome =
                  servico['nome'] as String;

              final valor =
                  servico['valor'] as double;

              final icone =
                  servico['icone'] as IconData;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(icone),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      Text(moeda.format(valor)),
                  trailing: const Icon(
                    Icons.add_circle,
                  ),
                  onTap: () async {
                    await widget.registrarServico(
                      nome,
                      valor,
                    );

                    await carregar();
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () async {
              await widget.outroGanho();
              await carregar();
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Outro ganho',
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () async {
              await widget.adicionarGasto();
              await carregar();
            },
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
            label: const Text(
              'Adicionar gasto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumo(
    String titulo,
    double valor,
    IconData icone,
    Color cor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icone,
              color: cor,
            ),
            const SizedBox(height: 6),
            Text(titulo),
            Text(
              moeda.format(valor),
              style: const TextStyle(
                fontSize: 18,
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
  State<EstoquePage> createState() =>
      _EstoquePageState();
}

class _EstoquePageState
    extends State<EstoquePage> {
  List<Map<String, dynamic>> produtos = [];

  Future<void> carregar() async {
    final dados =
        await DatabaseHelper.instance.buscarEstoque();

    if (!mounted) return;

    setState(() {
      produtos = dados;
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> adicionarProduto([
    Map<String, dynamic>? produto,
  ]) async {
    final nomeController = TextEditingController(
      text: produto?['nome']?.toString() ?? '',
    );

    final quantidadeController =
        TextEditingController(
      text:
          produto?['quantidade']?.toString() ?? '',
    );

    final compraController = TextEditingController(
      text: produto?['precoCompra']?.toString() ?? '',
    );

    final vendaController = TextEditingController(
      text:
          produto?['precoVenda']?.toString() ?? '',
    );

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            produto == null
                ? 'Adicionar estoque'
                : 'Editar estoque',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomeController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Modelo',
                    hintText:
                        'Ex.: Fox C',
                  ),
                ),

                TextField(
                  controller:
                      quantidadeController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Quantidade',
                  ),
                ),

                TextField(
                  controller:
                      compraController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Preço de compra',
                    prefixText: 'R\$ ',
                  ),
                ),

                TextField(
                  controller:
                      vendaController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Preço de venda',
                    prefixText: 'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (salvar == true) {
      final nome =
          nomeController.text.trim();

      final quantidade =
          int.tryParse(
                quantidadeController.text,
              ) ??
              0;

      final compra =
          converterValor(
        compraController.text,
      );

      final venda =
          converterValor(
        vendaController.text,
      );

      if (nome.isNotEmpty &&
          quantidade >= 0) {
        if (produto == null) {
          await DatabaseHelper.instance
              .adicionarEstoque(
            nome: nome,
            quantidade: quantidade,
            precoCompra: compra,
            precoVenda: venda,
          );
        } else {
          await DatabaseHelper.instance
              .atualizarEstoque(
            id: produto['id'] as int,
            nome: nome,
            quantidade: quantidade,
            precoCompra: compra,
            precoVenda: venda,
          );
        }

        await carregar();
      }
    }

    nomeController.dispose();
    quantidadeController.dispose();
    compraController.dispose();
    vendaController.dispose();
  }

  Future<void> registrarVenda(
    Map<String, dynamic> produto,
  ) async {
    final quantidade =
        (produto['quantidade'] as num).toInt();

    if (quantidade <= 0) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Produto sem estoque.'),
        ),
      );

      return;
    }

    final valor =
        (produto['precoVenda'] as num)
            .toDouble();

    await DatabaseHelper.instance
        .diminuirEstoque(
      produto['id'] as int,
      1,
    );

    await DatabaseHelper.instance
        .adicionarMovimentacao(
      tipo: 'ganho',
      categoria:
          'Estoque - ${produto['nome']}',
      valor: valor,
      data: formatoBanco.format(
        DateTime.now(),
      ),
    );

    await carregar();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrada: ${moeda.format(valor)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double investido = 0;
    double valorVenda = 0;

    for (final produto in produtos) {
      final quantidade =
          (produto['quantidade'] as num)
              .toDouble();

      final compra =
          (produto['precoCompra'] as num)
              .toDouble();

      final venda =
          (produto['precoVenda'] as num)
              .toDouble();

      investido += quantidade * compra;
      valorVenda += quantidade * venda;
    }

    final lucroPotencial =
        valorVenda - investido;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estoque de cílios',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo do estoque',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Investido: ${moeda.format(investido)}',
                  ),

                  Text(
                    'Valor de venda: ${moeda.format(valorVenda)}',
                  ),

                  Text(
                    'Lucro potencial: ${moeda.format(lucroPotencial)}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child:
                FilledButton.icon(
              onPressed:
                  () => adicionarProduto(),
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Adicionar modelo',
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (produtos.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'Nenhum modelo cadastrado.',
                  ),
                ),
              ),
            ),

          ...produtos.map(
            (produto) {
              final quantidade =
                  (produto['quantidade']
                          as num)
                      .toInt();

              final venda =
                  (produto['precoVenda']
                          as num)
                      .toDouble();

              final estoqueBaixo =
                  quantidade <= 2;

              return Card(
                child: ListTile(
                  leading:
                      CircleAvatar(
                    child: Icon(
                      estoqueBaixo
                          ? Icons.warning
                          : Icons
                              .inventory_2,
                    ),
                  ),

                  title: Text(
                    produto['nome'],
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    'Quantidade: $quantidade\n'
                    'Venda: ${moeda.format(venda)}'
                    '${estoqueBaixo ? '\n⚠️ Estoque baixo' : ''}',
                  ),

                  isThreeLine: true,

                  trailing:
                      PopupMenuButton<
                          String>(
                    onSelected:
                        (opcao) async {
                      if (opcao ==
                          'vender') {
                        await registrarVenda(
                          produto,
                        );
                      }

                      if (opcao ==
                          'editar') {
                        await adicionarProduto(
                          produto,
                        );
                      }

                      if (opcao ==
                          'excluir') {
                        await DatabaseHelper
                            .instance
                            .excluirEstoque(
                          produto['id']
                              as int,
                        );

                        await carregar();
                      }
                    },
                    itemBuilder:
                        (context) => const [
                      PopupMenuItem(
                        value: 'vender',
                        child: Text(
                          'Registrar venda',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'editar',
                        child: Text(
                          'Editar',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: Text(
                          'Excluir',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
  State<HistoricoPage> createState() =>
      _HistoricoPageState();
}

class _HistoricoPageState
    extends State<HistoricoPage> {
  List<Map<String, dynamic>> registros = [];

  Future<void> carregar() async {
    final dados =
        await DatabaseHelper.instance
            .buscarMovimentacoes();

    if (!mounted) return;

    setState(() {
      registros = dados;
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  Widget build(BuildContext context) {
    double ganhos = 0;
    double gastos = 0;

    for (final registro in registros) {
      final valor =
          (registro['valor'] as num)
              .toDouble();

      if (registro['tipo'] ==
          'ganho') {
        ganhos += valor;
      } else {
        gastos += valor;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo geral',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Ganhos: ${moeda.format(ganhos)}',
                    ),
                    Text(
                      'Gastos: ${moeda.format(gastos)}',
                    ),
                    Text(
                      'Lucro: ${moeda.format(ganhos - gastos)}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (registros.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'Nenhum registro.',
                  ),
                ),
              ),

            ...registros.map(
              (registro) {
                final ganho =
                    registro['tipo'] ==
                        'ganho';

                final valor =
                    (registro['valor']
                            as num)
                        .toDouble();

                final data =
                    DateTime.parse(
                  registro['data'],
                );

                return Card(
                  child: ListTile(
                    leading:
                        CircleAvatar(
                      child: Icon(
                        ganho
                            ? Icons
                                .arrow_upward
                            : Icons
                                .arrow_downward,
                      ),
                    ),

                    title: Text(
                      registro[
                          'categoria'],
                    ),

                    subtitle: Text(
                      formatoData
                          .format(data),
                    ),

                    trailing:
                        Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          '${ganho ? '+' : '-'} ${moeda.format(valor)}',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            color: ganho
                                ? Colors
                                    .green
                                : Colors
                                    .red,
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () async {
                            await DatabaseHelper
                                .instance
                                .excluirMovimentacao(
                              registro[
                                      'id']
                                  as int,
                            );

                            await carregar();
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
