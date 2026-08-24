import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ControleFinanceiroApp());
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// MODELOS
// ============================================================

class Movimentacao {
  final String id;
  final String tipo;
  final String descricao;
  final double valor;
  final DateTime data;

  Movimentacao({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
    };
  }

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: map['id'] ?? '',
      tipo: map['tipo'] ?? 'entrada',
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      data: DateTime.tryParse(map['data'] ?? '') ?? DateTime.now(),
    );
  }
}

class Produto {
  final String id;
  final String nome;
  final int quantidade;
  final double custo;
  final double venda;

  Produto({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.custo,
    required this.venda,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'custo': custo,
      'venda': venda,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      quantidade: map['quantidade'] ?? 0,
      custo: (map['custo'] as num?)?.toDouble() ?? 0,
      venda: (map['venda'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// ARMAZENAMENTO
// ============================================================

class AppStorage {
  static const String movimentacoesKey = 'movimentacoes';
  static const String produtosKey = 'produtos';

  static Future<List<Movimentacao>> carregarMovimentacoes() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(movimentacoesKey) ?? [];

    return dados
        .map(
          (item) =>
              Movimentacao.fromMap(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> salvarMovimentacoes(
    List<Movimentacao> movimentacoes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final dados = movimentacoes
        .map((item) => jsonEncode(item.toMap()))
        .toList();

    await prefs.setStringList(movimentacoesKey, dados);
  }

  static Future<List<Produto>> carregarProdutos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(produtosKey) ?? [];

    return dados
        .map(
          (item) => Produto.fromMap(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> salvarProdutos(List<Produto> produtos) async {
    final prefs = await SharedPreferences.getInstance();

    final dados = produtos.map((item) => jsonEncode(item.toMap())).toList();

    await prefs.setStringList(produtosKey, dados);
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
  int paginaAtual = 0;

  List<Movimentacao> movimentacoes = [];
  List<Produto> produtos = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final movimentos = await AppStorage.carregarMovimentacoes();
    final estoque = await AppStorage.carregarProdutos();

    if (!mounted) return;

    setState(() {
      movimentacoes = movimentos;
      produtos = estoque;
      carregando = false;
    });
  }

  double get totalEntradas {
    return movimentacoes
        .where((item) => item.tipo == 'entrada')
        .fold(0, (total, item) => total + item.valor);
  }

  double get totalSaidas {
    return movimentacoes
        .where((item) => item.tipo == 'saida')
        .fold(0, (total, item) => total + item.valor);
  }

  double get saldo => totalEntradas - totalSaidas;

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final paginas = [
      DashboardPage(
        entradas: totalEntradas,
        saidas: totalSaidas,
        saldo: saldo,
        produtos: produtos,
        movimentacoes: movimentacoes,
      ),
      EstoquePage(
        produtos: produtos,
        onAlterar: carregarDados,
      ),
      FinanceiroPage(
        movimentacoes: movimentacoes,
        onAlterar: carregarDados,
      ),
      RelatoriosPage(
        entradas: totalEntradas,
        saidas: totalSaidas,
        saldo: saldo,
        produtos: produtos,
        movimentacoes: movimentacoes,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: paginas[paginaAtual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaAtual,
        onDestinationSelected: (index) {
          setState(() {
            paginaAtual = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Estoque',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Financeiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final double entradas;
  final double saidas;
  final double saldo;
  final List<Produto> produtos;
  final List<Movimentacao> movimentacoes;

  const DashboardPage({
    super.key,
    required this.entradas,
    required this.saidas,
    required this.saldo,
    required this.produtos,
    required this.movimentacoes,
  });

  String moeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Visão geral',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Resumo financeiro e do estoque',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          _CardResumo(
            titulo: 'Saldo atual',
            valor: moeda(saldo),
            icone: Icons.account_balance_wallet,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _CardResumo(
                  titulo: 'Entradas',
                  valor: moeda(entradas),
                  icone: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardResumo(
                  titulo: 'Saídas',
                  valor: moeda(saidas),
                  icone: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _InfoCard(
            titulo: 'Estoque',
            icone: Icons.inventory_2,
            valor: '${produtos.length} produtos cadastrados',
          ),

          const SizedBox(height: 12),

          _InfoCard(
            titulo: 'Movimentações',
            icone: Icons.receipt_long,
            valor: '${movimentacoes.length} registros',
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aplicativo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sistema preparado para controle financeiro, '
                    'gestão de estoque e relatórios.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _CardResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 30),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String valor;

  const _InfoCard({
    required this.titulo,
    required this.icone,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icone),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(valor),
      ),
    );
  }
}

// ============================================================
// ESTOQUE
// ============================================================

class EstoquePage extends StatefulWidget {
  final List<Produto> produtos;
  final VoidCallback onAlterar;

  const EstoquePage({
    super.key,
    required this.produtos,
    required this.onAlterar,
  });

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  Future<void> adicionarProduto() async {
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final custoController = TextEditingController();
    final vendaController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do produto',
                  ),
                ),
                TextField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                  ),
                ),
                TextField(
                  controller: custoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Custo',
                  ),
                ),
                TextField(
                  controller: vendaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço de venda',
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

    if (resultado != true) return;

    final produto = Produto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nomeController.text.trim(),
      quantidade: int.tryParse(quantidadeController.text) ?? 0,
      custo: double.tryParse(
            custoController.text.replaceAll(',', '.'),
          ) ??
          0,
      venda: double.tryParse(
            vendaController.text.replaceAll(',', '.'),
          ) ??
          0,
    );

    final lista = [...widget.produtos, produto];

    await AppStorage.salvarProdutos(lista);

    widget.onAlterar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: adicionarProduto,
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Estoque',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.produtos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nenhum produto cadastrado.',
                  ),
                ),
              ),
            )
          else
            ...widget.produtos.map(
              (produto) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory),
                  ),
                  title: Text(
                    produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Quantidade: ${produto.quantidade}',
                  ),
                  trailing: Text(
                    'R\$ ${produto.venda.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
// FINANCEIRO
// ============================================================

class FinanceiroPage extends StatefulWidget {
  final List<Movimentacao> movimentacoes;
  final VoidCallback onAlterar;

  const FinanceiroPage({
    super.key,
    required this.movimentacoes,
    required this.onAlterar,
  });

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  Future<void> adicionarMovimentacao(String tipo) async {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            tipo == 'entrada' ? 'Nova entrada' : 'Nova saída',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
              ),
              TextField(
                controller: valorController,
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

    if (resultado != true) return;

    final valor = double.tryParse(
          valorController.text.replaceAll(',', '.'),
        ) ??
        0;

    if (valor <= 0) return;

    final movimentacao = Movimentacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: tipo,
      descricao: descricaoController.text.trim(),
      valor: valor,
      data: DateTime.now(),
    );

    final lista = [...widget.movimentacoes, movimentacao];

    await AppStorage.salvarMovimentacoes(lista);

    widget.onAlterar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Financeiro',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => adicionarMovimentacao('entrada'),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Entrada'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => adicionarMovimentacao('saida'),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Saída'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (widget.movimentacoes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nenhuma movimentação cadastrada.',
                  ),
                ),
              ),
            )
          else
            ...widget.movimentacoes.reversed.map(
              (item) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item.tipo == 'entrada'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                  ),
                  title: Text(
                    item.descricao.isEmpty
                        ? 'Movimentação'
                        : item.descricao,
                  ),
                  subtitle: Text(
                    '${item.data.day.toString().padLeft(2, '0')}/'
                    '${item.data.month.toString().padLeft(2, '0')}/'
                    '${item.data.year}',
                  ),
                  trailing: Text(
                    '${item.tipo == 'entrada' ? '+' : '-'} '
                    'R\$ ${item.valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
// RELATÓRIOS
// ============================================================

class RelatoriosPage extends StatelessWidget {
  final double entradas;
  final double saidas;
  final double saldo;
  final List<Produto> produtos;
  final List<Movimentacao> movimentacoes;

  const RelatoriosPage({
    super.key,
    required this.entradas,
    required this.saidas,
    required this.saldo,
    required this.produtos,
    required this.movimentacoes,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Relatórios',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo financeiro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Entradas: R\$ ${entradas.toStringAsFixed(2)}',
                ),
                Text(
                  'Saídas: R\$ ${saidas.toStringAsFixed(2)}',
                ),
                Text(
                  'Saldo: R\$ ${saldo.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produtos'),
            subtitle: Text(
              '${produtos.length} produtos cadastrados',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Movimentações'),
            subtitle: Text(
              '${movimentacoes.length} movimentações registradas',
            ),
          ),
        ),
      ],
    );
  }
}
