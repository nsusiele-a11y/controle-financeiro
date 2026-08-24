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
// MODELO DE PRODUTO
// ============================================================

class Produto {
  final String id;
  final String sku;
  final String nome;
  final String categoria;
  final int quantidade;
  final int estoqueMinimo;
  final double custo;
  final double venda;

  Produto({
    required this.id,
    required this.sku,
    required this.nome,
    required this.categoria,
    required this.quantidade,
    required this.estoqueMinimo,
    required this.custo,
    required this.venda,
  });

  double get valorEstoque => quantidade * custo;

  double get lucroUnitario => venda - custo;

  bool get estoqueBaixo => quantidade <= estoqueMinimo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'estoqueMinimo': estoqueMinimo,
      'custo': custo,
      'venda': venda,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? 'Geral',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
      estoqueMinimo: (map['estoqueMinimo'] as num?)?.toInt() ?? 0,
      custo: (map['custo'] as num?)?.toDouble() ?? 0,
      venda: (map['venda'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// MODELO FINANCEIRO
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
      id: map['id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'entrada',
      descricao: map['descricao']?.toString() ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      data: DateTime.tryParse(map['data']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ============================================================
// ARMAZENAMENTO
// ============================================================

class AppStorage {
  static const produtosKey = 'produtos';
  static const movimentacoesKey = 'movimentacoes';

  static Future<List<Produto>> carregarProdutos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(produtosKey) ?? [];

    return dados
        .map(
          (item) => Produto.fromMap(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> salvarProdutos(List<Produto> produtos) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      produtosKey,
      produtos.map((produto) => jsonEncode(produto.toMap())).toList(),
    );
  }

  static Future<List<Movimentacao>> carregarMovimentacoes() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(movimentacoesKey) ?? [];

    return dados
        .map(
          (item) => Movimentacao.fromMap(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> salvarMovimentacoes(
    List<Movimentacao> movimentacoes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      movimentacoesKey,
      movimentacoes
          .map((movimentacao) => jsonEncode(movimentacao.toMap()))
          .toList(),
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
  int paginaAtual = 0;

  List<Produto> produtos = [];
  List<Movimentacao> movimentacoes = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final produtosSalvos = await AppStorage.carregarProdutos();
    final movimentacoesSalvas =
        await AppStorage.carregarMovimentacoes();

    if (!mounted) return;

    setState(() {
      produtos = produtosSalvos;
      movimentacoes = movimentacoesSalvas;
      carregando = false;
    });
  }

  double get entradas {
    return movimentacoes
        .where((item) => item.tipo == 'entrada')
        .fold(0, (total, item) => total + item.valor);
  }

  double get saidas {
    return movimentacoes
        .where((item) => item.tipo == 'saida')
        .fold(0, (total, item) => total + item.valor);
  }

  double get saldo => entradas - saidas;

  double get valorEstoque {
    return produtos.fold(
      0,
      (total, produto) => total + produto.valorEstoque,
    );
  }

  int get produtosEstoqueBaixo {
    return produtos.where((produto) => produto.estoqueBaixo).length;
  }

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
        entradas: entradas,
        saidas: saidas,
        saldo: saldo,
        valorEstoque: valorEstoque,
        produtosEstoqueBaixo: produtosEstoqueBaixo,
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
        entradas: entradas,
        saidas: saidas,
        saldo: saldo,
        valorEstoque: valorEstoque,
        produtos: produtos,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
            icon: Icon(Icons.account_balance_wallet_outlined),
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
  final double valorEstoque;
  final int produtosEstoqueBaixo;

  const DashboardPage({
    super.key,
    required this.entradas,
    required this.saidas,
    required this.saldo,
    required this.valorEstoque,
    required this.produtosEstoqueBaixo,
  });

  String moeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Resumo da sua operação',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 20),

        _ResumoCard(
          titulo: 'Saldo',
          valor: moeda(saldo),
          icone: Icons.account_balance_wallet,
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _ResumoCard(
                titulo: 'Entradas',
                valor: moeda(entradas),
                icone: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ResumoCard(
                titulo: 'Saídas',
                valor: moeda(saidas),
                icone: Icons.arrow_upward,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _ResumoCard(
          titulo: 'Valor do estoque',
          valor: moeda(valorEstoque),
          icone: Icons.inventory_2,
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                produtosEstoqueBaixo > 0
                    ? Icons.warning
                    : Icons.check_circle,
              ),
            ),
            title: const Text(
              'Estoque baixo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              produtosEstoqueBaixo == 0
                  ? 'Nenhum produto abaixo do mínimo'
                  : '$produtosEstoqueBaixo produto(s) precisam de reposição',
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ResumoCard({
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
  String busca = '';

  List<Produto> get produtosFiltrados {
    if (busca.trim().isEmpty) {
      return widget.produtos;
    }

    final texto = busca.toLowerCase();

    return widget.produtos.where((produto) {
      return produto.nome.toLowerCase().contains(texto) ||
          produto.sku.toLowerCase().contains(texto) ||
          produto.categoria.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> abrirProduto([Produto? produto]) async {
    final nomeController =
        TextEditingController(text: produto?.nome ?? '');
    final skuController =
        TextEditingController(text: produto?.sku ?? '');
    final categoriaController =
        TextEditingController(text: produto?.categoria ?? '');
    final quantidadeController = TextEditingController(
      text: produto?.quantidade.toString() ?? '0',
    );
    final minimoController = TextEditingController(
      text: produto?.estoqueMinimo.toString() ?? '0',
    );
    final custoController = TextEditingController(
      text: produto?.custo.toStringAsFixed(2) ?? '',
    );
    final vendaController = TextEditingController(
      text: produto?.venda.toStringAsFixed(2) ?? '',
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            produto == null
                ? 'Cadastrar produto'
                : 'Editar produto',
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: skuController,
                    decoration: const InputDecoration(
                      labelText: 'Código / SKU',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: categoriaController,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minimoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estoque mínimo',
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: custoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Custo',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vendaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
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

    final nome = nomeController.text.trim();

    if (nome.isEmpty) {
      return;
    }

    final novoProduto = Produto(
      id: produto?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      sku: skuController.text.trim(),
      nome: nome,
      categoria: categoriaController.text.trim().isEmpty
          ? 'Geral'
          : categoriaController.text.trim(),
      quantidade:
          int.tryParse(quantidadeController.text) ?? 0,
      estoqueMinimo:
          int.tryParse(minimoController.text) ?? 0,
      custo: double.tryParse(
            custoController.text.replaceAll(',', '.'),
          ) ??
          0,
      venda: double.tryParse(
            vendaController.text.replaceAll(',', '.'),
          ) ??
          0,
    );

    final lista = [...widget.produtos];

    if (produto == null) {
      lista.add(novoProduto);
    } else {
      final index =
          lista.indexWhere((item) => item.id == produto.id);

      if (index >= 0) {
        lista[index] = novoProduto;
      }
    }

    await AppStorage.salvarProdutos(lista);

    widget.onAlterar();
  }

  Future<void> excluirProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir produto?'),
          content: Text(
            'Deseja realmente excluir "${produto.nome}"?',
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

    final lista = widget.produtos
        .where((item) => item.id != produto.id)
        .toList();

    await AppStorage.salvarProdutos(lista);

    widget.onAlterar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = produtosFiltrados;

    final valorTotal = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorEstoque,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirProduto(),
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
            '${widget.produtos.length} produtos • '
            'R\$ ${valorTotal.toStringAsFixed(2)} em estoque',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            onChanged: (valor) {
              setState(() {
                busca = valor;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar produto, SKU ou categoria...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: busca.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          busca = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (lista.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    widget.produtos.isEmpty
                        ? 'Nenhum produto cadastrado.'
                        : 'Nenhum produto encontrado.',
                  ),
                ),
              ),
            ),

          ...lista.map(
            (produto) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
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
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    'SKU: ${produto.sku.isEmpty ? '-' : produto.sku}\n'
                    'Categoria: ${produto.categoria}\n'
                    'Custo: R\$ ${produto.custo.toStringAsFixed(2)} • '
                    'Venda: R\$ ${produto.venda.toStringAsFixed(2)}',
                  ),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (opcao) {
                    if (opcao == 'editar') {
                      abrirProduto(produto);
                    }

                    if (opcao == 'excluir') {
                      excluirProduto(produto);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Text('Excluir'),
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
            tipo == 'entrada'
                ? 'Nova entrada'
                : 'Nova saída',
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

    final lista = [
      ...widget.movimentacoes,
      movimentacao,
    ];

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
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      adicionarMovimentacao('entrada'),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Entrada'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      adicionarMovimentacao('saida'),
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
            ),

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
  final double valorEstoque;
  final List<Produto> produtos;

  const RelatoriosPage({
    super.key,
    required this.entradas,
    required this.saidas,
    required this.saldo,
    required this.valorEstoque,
    required this.produtos,
  });

  @override
  Widget build(BuildContext context) {
    final estoqueBaixo =
        produtos.where((produto) => produto.estoqueBaixo).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Relatórios',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
            leading: const Icon(Icons.inventory_2),
            title: const Text('Valor do estoque'),
            subtitle: Text(
              'R\$ ${valorEstoque.toStringAsFixed(2)}',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produtos cadastrados'),
            subtitle: Text(
              '${produtos.length} produtos',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Estoque baixo'),
            subtitle: Text(
              '$estoqueBaixo produto(s) abaixo do mínimo',
            ),
          ),
        ),
      ],
    );
  }
}
