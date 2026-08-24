import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuControleApp());
}

final moeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final dataFormatada = DateFormat('dd/MM/yyyy');

String dataBanco(DateTime data) {
  return DateFormat('yyyy-MM-dd').format(data);
}

double valorNumero(String texto) {
  return double.tryParse(
        texto
            .replaceAll('.', '')
            .replaceAll(',', '.'),
      ) ??
      0;
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

  factory Movimentacao.fromMap(
    Map<String, dynamic> map,
  ) {
    return Movimentacao(
      id: map['id'].toString(),
      tipo: map['tipo'].toString(),
      categoria: map['categoria'].toString(),
      valor: (map['valor'] as num).toDouble(),
      data: map['data'].toString(),
    );
  }
}

// ============================================================
// MODELO DE ESTOQUE
// ============================================================

class Produto {
  final String id;
  final String nome;
  final int quantidade;
  final double precoCompra;
  final double precoVenda;

  Produto({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.precoCompra,
    required this.precoVenda,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'precoCompra': precoCompra,
      'precoVenda': precoVenda,
    };
  }

  factory Produto.fromMap(
    Map<String, dynamic> map,
  ) {
    return Produto(
      id: map['id'].toString(),
      nome: map['nome'].toString(),
      quantidade:
          (map['quantidade'] as num).toInt(),
      precoCompra:
          (map['precoCompra'] as num).toDouble(),
      precoVenda:
          (map['precoVenda'] as num).toDouble(),
    );
  }
}

// ============================================================
// ARMAZENAMENTO
// ============================================================

class Storage {
  static const String movimentacoesKey =
      'movimentacoes';

  static const String estoqueKey =
      'estoque';

  static Future<List<Movimentacao>>
      movimentacoes() async {
    final prefs =
        await SharedPreferences.getInstance();

    final lista =
        prefs.getStringList(
      movimentacoesKey,
    );

    if (lista == null) {
      return [];
    }

    return lista.map((item) {
      return Movimentacao.fromMap(
        jsonDecode(item)
            as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarMovimentacoes(
    List<Movimentacao> lista,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      movimentacoesKey,
      lista
          .map(
            (item) =>
                jsonEncode(item.toMap()),
          )
          .toList(),
    );
  }

  static Future<List<Produto>> estoque() async {
    final prefs =
        await SharedPreferences.getInstance();

    final lista =
        prefs.getStringList(estoqueKey);

    if (lista == null) {
      return [];
    }

    return lista.map((item) {
      return Produto.fromMap(
        jsonDecode(item)
            as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarEstoque(
    List<Produto> lista,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      estoqueKey,
      lista
          .map(
            (item) =>
                jsonEncode(item.toMap()),
          )
          .toList(),
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
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pagina = 0;

  DateTime dataSelecionada =
      DateTime.now();

  Future<void> registrarGanho(
    String categoria,
    double valor,
  ) async {
    final lista =
        await Storage.movimentacoes();

    lista.add(
      Movimentacao(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        tipo: 'ganho',
        categoria: categoria,
        valor: valor,
        data: dataBanco(
          dataSelecionada,
        ),
      ),
    );

    await Storage.salvarMovimentacoes(
      lista,
    );

    setState(() {});
  }

  Future<void> adicionarGasto() async {
    final categoria =
        TextEditingController();

    final valor =
        TextEditingController();

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Adicionar gasto'),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller: categoria,
                decoration:
                    const InputDecoration(
                  labelText: 'Descrição',
                ),
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
              onPressed: () async {
                final valorFinal =
                    valorNumero(
                  valor.text,
                );

                if (categoria.text
                        .trim()
                        .isEmpty ||
                    valorFinal <= 0) {
                  return;
                }

                final lista =
                    await Storage
                        .movimentacoes();

                lista.add(
                  Movimentacao(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    tipo: 'gasto',
                    categoria:
                        categoria.text
                            .trim(),
                    valor: valorFinal,
                    data: dataBanco(
                      dataSelecionada,
                    ),
                  ),
                );

                await Storage
                    .salvarMovimentacoes(
                  lista,
                );

                if (context.mounted) {
                  Navigator.pop(
                    context,
                    true,
                  );
                }
              },
              child:
                  const Text('Salvar'),
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
    final valor =
        TextEditingController();

    final resultado =
        await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Outro ganho'),
          content: TextField(
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valorFinal =
                    valorNumero(
                  valor.text,
                );

                if (valorFinal > 0) {
                  Navigator.pop(
                    context,
                    valorFinal,
                  );
                }
              },
              child:
                  const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    valor.dispose();

    if (resultado != null) {
      await registrarGanho(
        'Outro ganho',
        resultado,
      );
    }
  }

  Future<void> escolherData() async {
    final data =
        await showDatePicker(
      context: context,
      initialDate:
          dataSelecionada,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2100),
    );

    if (data != null) {
      setState(() {
        dataSelecionada =
            data;
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

  Future<void> carregar() async {
    final lista =
        await Storage.movimentacoes();

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
    });
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lucro =
        ganhos - gastos;

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
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
                icon: const Icon(
                  Icons.calendar_month,
                ),
              ),
            ],
          ),

          Text(
            dataFormatada.format(
              widget.data,
            ),
            style: const TextStyle(
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
                    moeda.format(
                      lucro,
                    ),
                    style:
                        TextStyle(
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
                  Icons
                      .arrow_upward,
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
                  Icons
                      .arrow_downward,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Atendimentos',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

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

          const SizedBox(
            height: 8,
          ),

          OutlinedButton.icon(
            onPressed:
                () async {
              await widget
                  .onOutroGanho();
              await carregar();
            },
            icon:
                const Icon(Icons.add),
            label: const Text(
              'Outro ganho',
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          FilledButton.icon(
            onPressed:
                () async {
              await widget
                  .onGasto();
              await carregar();
            },
            icon: const Icon(
              Icons.remove_circle,
            ),
            label: const Text(
              'Adicionar gasto',
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
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle:
            Text(moeda.format(valor)),
        trailing:
            const Icon(
          Icons.add_circle,
        ),
        onTap: () async {
          await widget.onGanho(
            nome,
            valor,
          );
          await carregar();
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
              moeda.format(valor),
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
//
