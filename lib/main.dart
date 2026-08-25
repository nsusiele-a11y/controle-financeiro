import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuControleApp());
}

// ============================================================
// FORMATAÇÃO
// ============================================================

final NumberFormat moeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat dataFormatada = DateFormat('dd/MM/yyyy');

String dataBanco(DateTime data) {
  return DateFormat('yyyy-MM-dd').format(data);
}

double valorNumero(String texto) {
  final valor = texto.trim();

  if (valor.isEmpty) return 0;

  return double.tryParse(
        valor.replaceAll('.', '').replaceAll(',', '.'),
      ) ??
      0;
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

  double get valorVendaEstoque => quantidade * venda;

  double get lucroUnitario => venda - custo;

  double get lucroEstoque => quantidade * lucroUnitario;

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
  final String categoria;
  final String descricao;
  final double valor;
  final String data;

  Movimentacao({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'categoria': categoria,
      'descricao': descricao,
      'valor': valor,
      'data': data,
    };
  }

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: map['id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'ganho',
      categoria: map['categoria']?.toString() ?? 'Outros',
      descricao: map['descricao']?.toString() ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      data: map['data']?.toString() ?? dataBanco(DateTime.now()),
    );
  }
}

// ============================================================
// ARMAZENAMENTO
// ============================================================

class Storage {
  static const String movimentacoesKey = 'movimentacoes';
  static const String estoqueKey = 'estoque';

  static Future<List<Movimentacao>> movimentacoes() async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList(movimentacoesKey);

    if (lista == null) return [];

    return lista.map((item) {
      try {
        return Movimentacao.fromMap(
          jsonDecode(item) as Map<String, dynamic>,
        );
      } catch (_) {
        return Movimentacao(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          tipo: 'ganho',
          categoria: 'Outros',
          descricao: '',
          valor: 0,
          data: dataBanco(DateTime.now()),
        );
      }
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

  List<Produto> produtos = [];
  List<Movimentacao> movimentacoes = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final produtosSalvos = await Storage.estoque();
    final movimentacoesSalvas = await Storage.movimentacoes();

    if (!mounted) return;

    setState(() {
      produtos = produtosSalvos;
      movimentacoes = movimentacoesSalvas;
      carregando = false;
    });
  }

  Future<void> registrarGanho(
    String categoria,
    double valor,
  ) async {
    if (valor <= 0) return;

    final lista = [...movimentacoes];

    lista.add(
      Movimentacao(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: 'ganho',
        categoria: categoria,
        descricao: categoria,
        valor: valor,
        data: dataBanco(dataSelecionada),
      ),
    );

    await Storage.salvarMovimentacoes(lista);
    await carregarDados();
  }

  Future<void> adicionarGasto() async {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valor = valorNumero(valorController.text);

                if (descricaoController.text.trim().isEmpty ||
                    valor <= 0) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      descricaoController.dispose();
      valorController.dispose();
      return;
    }

    final descricao = descricaoController.text.trim();
    final valor = valorNumero(valorController.text);

    descricaoController.dispose();
    valorController.dispose();

    if (valor <= 0) return;

    final lista = [...movimentacoes];

    lista.add(
      Movimentacao(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: 'gasto',
        categoria: 'Gasto',
        descricao: descricao,
        valor: valor,
        data: dataBanco(dataSelecionada),
      ),
    );

    await Storage.salvarMovimentacoes(lista);
    await carregarDados();
  }

  Future<void> outroGanho() async {
    final descricaoController = TextEditingController(
      text: 'Outro ganho',
    );
    final valorController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Outro ganho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valor = valorNumero(valorController.text);

                if (valor <= 0) return;

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      descricaoController.dispose();
      valorController.dispose();
      return;
    }

    final descricao = descricaoController.text.trim().isEmpty
        ? 'Outro ganho'
        : descricaoController.text.trim();

    final valor = valorNumero(valorController.text);

    descricaoController.dispose();
    valorController.dispose();

    if (valor <= 0) return;

    await registrarGanho(descricao, valor);
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
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final paginas = [
      DashboardPage(
        data: dataSelecionada,
        onData: escolherData,
        onGanho: registrarGanho,
        onGasto: adicionarGasto,
        onOutroGanho: outroGanho,
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
        dataSelecionada: dataSelecionada,
      ),
      RelatoriosPage(
        produtos: produtos,
        movimentacoes: movimentacoes,
      ),
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

class DashboardPage extends StatefulWidget {
  final DateTime data;
  final VoidCallback onData;

  final Future<void> Function(String, double) onGanho;
  final Future<void> Function() onGasto;
  final Future<void> Function() onOutroGanho;

  final List<Produto> produtos;
  final List<Movimentacao> movimentacoes;

  const DashboardPage({
    super.key,
    required this.data,
    required this.onData,
    required this.onGanho,
    required this.onGasto,
    required this.onOutroGanho,
    required this.produtos,
    required this.movimentacoes,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final data = dataBanco(widget.data);

    double ganhos = 0;
    double gastos = 0;
    int atendimentos = 0;

    for (final item in widget.movimentacoes) {
      if (item.data != data) continue;

      if (item.tipo == 'ganho') {
        ganhos += item.valor;
        atendimentos++;
      } else {
        gastos += item.valor;
      }
    }

    final lucro = ganhos - gastos;

    final valorEstoque = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorEstoque,
    );

    final valorVendaEstoque = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorVendaEstoque,
    );

    final lucroEstoque = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.lucroEstoque,
    );

    final estoqueBaixo = widget.produtos
        .where((produto) => produto.estoqueBaixo)
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
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
              ),
            ],
          ),

          Text(
            dataFormatada.format(widget.data),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

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
                    '$atendimentos registros no dia',
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

          const SizedBox(height: 20),

          const Text(
            'Atendimentos',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          _servico(
            'Cílios normal',
            120,
            Icons.remove_red_eye,
          ),

          _servico(
            'Fox',
            150,
            Icons.auto_awesome,
          ),

          _servico(
            'Sobrancelha',
            30,
            Icons.face,
          ),

          _servico(
            'Manutenção',
            80,
            Icons.build,
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: widget.onOutroGanho,
            icon: const Icon(Icons.add),
            label: const Text('Outro ganho'),
          ),

          const SizedBox(height: 10),

          FilledButton.icon(
            onPressed: widget.onGasto,
            icon: const Icon(Icons.remove_circle),
            label: const Text('Adicionar gasto'),
          ),

          const SizedBox(height: 22),

          const Text(
            'Resumo do estoque',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          _infoCard(
            'Valor investido no estoque',
            moeda.format(valorEstoque),
            Icons.inventory_2,
          ),

          _infoCard(
            'Valor de venda do estoque',
            moeda.format(valorVendaEstoque),
            Icons.sell,
          ),

          _infoCard(
            'Lucro potencial do estoque',
            moeda.format(lucroEstoque),
            Icons.trending_up,
          ),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  estoqueBaixo > 0
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
                estoqueBaixo == 0
                    ? 'Nenhum produto abaixo do mínimo'
                    : '$estoqueBaixo produto(s) precisam de reposição',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servico(
    String nome,
    double valor,
    IconData icone,
  ) {
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
        subtitle: Text(
          moeda.format(valor),
        ),
        trailing: const Icon(
          Icons.add_circle,
        ),
        onTap: () async {
          await widget.onGanho(nome, valor);

          if (mounted) {
            setState(() {});
          }
        },
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
            Icon(
              icone,
              color: cor,
            ),
            const SizedBox(height: 5),
            Text(titulo),
            const SizedBox(height: 3),
            Text(
              moeda.format(valor),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    String titulo,
    String valor,
    IconData icone,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icone),
        title: Text(titulo),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
    final nomeController = TextEditingController(
      text: produto?.nome ?? '',
    );

    final skuController = TextEditingController(
      text: produto?.sku ?? '',
    );

    final categoriaController = TextEditingController(
      text: produto?.categoria ?? '',
    );

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
      builder: (dialogContext) {
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Custo de compra',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vendaController,
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      nomeController.dispose();
      skuController.dispose();
      categoriaController.dispose();
      quantidadeController.dispose();
      minimoController.dispose();
      custoController.dispose();
      vendaController.dispose();
      return;
    }

    final nome = nomeController.text.trim();

    if (nome.isEmpty) {
      nomeController.dispose();
      skuController.dispose();
      categoriaController.dispose();
      quantidadeController.dispose();
      minimoController.dispose();
      custoController.dispose();
      vendaController.dispose();
      return;
    }

    final novoProduto = Produto(
      id: produto?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sku: skuController.text.trim(),
      nome: nome,
      categoria: categoriaController.text.trim().isEmpty
          ? 'Geral'
          : categoriaController.text.trim(),
      quantidade: int.tryParse(
            quantidadeController.text,
          ) ??
          0,
      estoqueMinimo: int.tryParse(
            minimoController.text,
          ) ??
          0,
      custo: valorNumero(
        custoController.text,
      ),
      venda: valorNumero(
        vendaController.text,
      ),
    );

    nomeController.dispose();
    skuController.dispose();
    categoriaController.dispose();
    quantidadeController.dispose();
    minimoController.dispose();
    custoController.dispose();
    vendaController.dispose();

    final lista = [...widget.produtos];

    if (produto == null) {
      lista.add(novoProduto);
    } else {
      final index = lista.indexWhere(
        (item) => item.id == produto.id,
      );

      if (index >= 0) {
        lista[index] = novoProduto;
      }
    }

    await Storage.salvarEstoque(lista);

    widget.onAlterar();
  }

  Future<void> excluirProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir produto?'),
          content: Text(
            'Deseja realmente excluir "${produto.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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

    await Storage.salvarEstoque(lista);

    widget.onAlterar();
  }

  Future<void> alterarQuantidade(
    Produto produto,
    int quantidade,
  ) async {
    final lista = [...widget.produtos];

    final index = lista.indexWhere(
      (item) => item.id == produto.id,
    );

    if (index < 0) return;

    lista[index] = Produto(
      id: produto.id,
      sku: produto.sku,
      nome: produto.nome,
      categoria: produto.categoria,
      quantidade: quantidade < 0 ? 0 : quantidade,
      estoqueMinimo: produto.estoqueMinimo,
      custo: produto.custo,
      venda: produto.venda,
    );

    await Storage.salvarEstoque(lista);

    widget.onAlterar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = produtosFiltrados;

    final valorTotal = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorEstoque,
    );

    final valorVenda = widget.produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorVendaEstoque,
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
            '${widget.produtos.length} produtos',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Investido: ${moeda.format(valorTotal)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            'Venda prevista: ${moeda.format(valorVenda)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
                          'Custo: ${moeda.format(produto.custo)} • '
                          'Venda: ${moeda.format(produto.venda)}\n'
                          'Lucro/un.: ${moeda.format(produto.lucroUnitario)}',
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

                    const Divider(),

                    Row(
                      children: [
                        const Text(
                          'Quantidade:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: produto.quantidade > 0
                              ? () => alterarQuantidade(
                                    produto,
                                    produto.quantidade - 1,
                                  )
                              : null,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                          ),
                        ),
                        Text(
                          '${produto.quantidade}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => alterarQuantidade(
                            produto,
                            produto.quantidade + 1,
                          ),
                          icon: const Icon(
                            Icons.add_circle_outline,
                          ),
                        ),
                      ],
                    ),

                    if (produto.estoqueBaixo)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '⚠ Estoque baixo — mínimo: ${produto.estoqueMinimo}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
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
// FINANCEIRO
// ============================================================

class FinanceiroPage extends StatelessWidget {
  final List<Movimentacao> movimentacoes;
  final VoidCallback onAlterar;
  final DateTime dataSelecionada;

  const FinanceiroPage({
    super.key,
    required this.movimentacoes,
    required this.onAlterar,
    required this.dataSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final ganhos = movimentacoes
        .where((item) => item.tipo == 'ganho')
        .fold<double>(
          0,
          (total, item) => total + item.valor,
        );

    final gastos = movimentacoes
        .where((item) => item.tipo == 'gasto')
        .fold<double>(
          0,
          (total, item) => total + item.valor,
        );

    final saldo = ganhos - gastos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Financeiro',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Todas as movimentações',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _linhaResumo(
                  'Ganhos',
                  ganhos,
                  Colors.green,
                ),
                _linhaResumo(
                  'Gastos',
                  gastos,
                  Colors.red,
                ),
                const Divider(),
                _linhaResumo(
                  'Saldo',
                  saldo,
                  saldo >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        ...movimentacoes.reversed.map(
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
                item.descricao.isEmpty
                    ? item.categoria
                    : item.descricao,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${item.categoria} • ${_formatarData(item.data)}',
              ),
              trailing: Text(
                '${item.tipo == 'ganho' ? '+' : '-'} '
                '${moeda.format(item.valor)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item.tipo == 'ganho'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ),
        ),

        if (movimentacoes.isEmpty)
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
      ],
    );
  }

  Widget _linhaResumo(
    String titulo,
    double valor,
    Color cor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            moeda.format(valor),
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String data) {
    try {
      final partes = data.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}

    return data;
  }
}

// ============================================================
// RELATÓRIOS
// ============================================================

class RelatoriosPage extends StatelessWidget {
  final List<Produto> produtos;
  final List<Movimentacao> movimentacoes;

  const RelatoriosPage({
    super.key,
    required this.produtos,
    required this.movimentacoes,
  });

  @override
  Widget build(BuildContext context) {
    final ganhos = movimentacoes
        .where((item) => item.tipo == 'ganho')
        .fold<double>(
          0,
          (total, item) => total + item.valor,
        );

    final gastos = movimentacoes
        .where((item) => item.tipo == 'gasto')
        .fold<double>(
          0,
          (total, item) => total + item.valor,
        );

    final saldo = ganhos - gastos;

    final valorEstoque = produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorEstoque,
    );

    final valorVenda = produtos.fold<double>(
      0,
      (total, produto) => total + produto.valorVendaEstoque,
    );

    final lucroEstoque = produtos.fold<double>(
      0,
      (total, produto) => total + produto.lucroEstoque,
    );

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

        const SizedBox(height: 18),

        const Text(
          'Financeiro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _linha(
                  'Total de ganhos',
                  moeda.format(ganhos),
                ),
                _linha(
                  'Total de gastos',
                  moeda.format(gastos),
                ),
                const Divider(),
                _linha(
                  'Saldo',
                  moeda.format(saldo),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Estoque',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _linha(
                  'Produtos cadastrados',
                  '${produtos.length}',
                ),
                _linha(
                  'Valor investido',
                  moeda.format(valorEstoque),
                ),
                _linha(
                  'Valor de venda previsto',
                  moeda.format(valorVenda),
                ),
                _linha(
                  'Lucro potencial',
                  moeda.format(lucroEstoque),
                ),
                _linha(
                  'Estoque baixo',
                  '$estoqueBaixo produto(s)',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Resumo geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text(
              'Movimentações registradas',
            ),
            subtitle: Text(
              '${movimentacoes.length} movimentação(ões)',
            ),
          ),
        ),
      ],
    );
  }

  Widget _linha(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
