import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
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
      title: 'Controle Financeiro',
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

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), 'controle_financeiro.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE movimentacoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            categoria TEXT NOT NULL,
            valor REAL NOT NULL,
            data TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> inserir({
    required String tipo,
    required String categoria,
    required double valor,
    required String data,
  }) async {
    final db = await database;

    return db.insert('movimentacoes', {
      'tipo': tipo,
      'categoria': categoria,
      'valor': valor,
      'data': data,
    });
  }

  Future<List<Map<String, dynamic>>> buscarTodos() async {
    final db = await database;

    return db.query(
      'movimentacoes',
      orderBy: 'data DESC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> buscarPorData(String data) async {
    final db = await database;

    return db.query(
      'movimentacoes',
      where: 'data = ?',
      whereArgs: [data],
      orderBy: 'id DESC',
    );
  }

  Future<int> excluir(int id) async {
    final db = await database;

    return db.delete(
      'movimentacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double valorCliente = 120.0;
  static const double valorManutencao = 80.0;

  int clientes = 0;
  int manutencoes = 0;
  double gastos = 0;

  DateTime dataSelecionada = DateTime.now();

  final DateFormat formatoData = DateFormat('yyyy-MM-dd');
  final DateFormat formatoExibicao = DateFormat('dd/MM/yyyy');

  double get ganhos =>
      (clientes * valorCliente) + (manutencoes * valorManutencao);

  double get lucro => ganhos - gastos;

  String moeda(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valor);
  }

  Future<void> carregarDia() async {
    final data = formatoData.format(dataSelecionada);

    final registros = await DatabaseHelper.instance.buscarPorData(data);

    int novosClientes = 0;
    int novasManutencoes = 0;
    double novosGastos = 0;

    for (final registro in registros) {
      final tipo = registro['tipo'];
      final categoria = registro['categoria'];
      final valor = (registro['valor'] as num).toDouble();

      if (tipo == 'ganho' && categoria == 'Cliente') {
        novosClientes++;
      }

      if (tipo == 'ganho' && categoria == 'Manutenção') {
        novasManutencoes++;
      }

      if (tipo == 'gasto') {
        novosGastos += valor;
      }
    }

    setState(() {
      clientes = novosClientes;
      manutencoes = novasManutencoes;
      gastos = novosGastos;
    });
  }

  Future<void> adicionarCliente() async {
    await DatabaseHelper.instance.inserir(
      tipo: 'ganho',
      categoria: 'Cliente',
      valor: valorCliente,
      data: formatoData.format(dataSelecionada),
    );

    await carregarDia();
  }

  Future<void> adicionarManutencao() async {
    await DatabaseHelper.instance.inserir(
      tipo: 'ganho',
      categoria: 'Manutenção',
      valor: valorManutencao,
      data: formatoData.format(dataSelecionada),
    );

    await carregarDia();
  }

  Future<void> adicionarGasto() async {
    final controller = TextEditingController();

    final valor = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar gasto'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              hintText: 'Ex.: 50,00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto = controller.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.');

                final valor = double.tryParse(texto);

                if (valor != null && valor > 0) {
                  Navigator.pop(context, valor);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (valor == null) return;

    await DatabaseHelper.instance.inserir(
      tipo: 'gasto',
      categoria: 'Gasto',
      valor: valor,
      data: formatoData.format(dataSelecionada),
    );

    await carregarDia();
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });

      await carregarDia();
    }
  }

  void diminuirCliente() {
    if (clientes <= 0) return;

    excluirUltimo('Cliente');
  }

  void diminuirManutencao() {
    if (manutencoes <= 0) return;

    excluirUltimo('Manutenção');
  }

  Future<void> excluirUltimo(String categoria) async {
    final registros = await DatabaseHelper.instance.buscarPorData(
      formatoData.format(dataSelecionada),
    );

    final encontrados = registros
        .where((r) =>
            r['tipo'] == 'ganho' && r['categoria'] == categoria)
        .toList();

    if (encontrados.isEmpty) return;

    final id = encontrados.first['id'] as int;

    await DatabaseHelper.instance.excluir(id);

    await carregarDia();
  }

  Future<void> abrirHistorico() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoricoPage(),
      ),
    );

    await carregarDia();
  }

  @override
  void initState() {
    super.initState();
    carregarDia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: abrirHistorico,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: carregarDia,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: selecionarData,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data selecionada',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            formatoExibicao.format(dataSelecionada),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            AtendimentoCard(
              titulo: 'Clientes novos',
              valorUnitario: valorCliente,
              quantidade: clientes,
              icone: Icons.person_add,
              onAdicionar: adicionarCliente,
              onRemover: diminuirCliente,
              moeda: moeda,
            ),

            const SizedBox(height: 12),

            AtendimentoCard(
              titulo: 'Manutenções',
              valorUnitario: valorManutencao,
              quantidade: manutencoes,
              icone: Icons.build,
              onAdicionar: adicionarManutencao,
              onRemover: diminuirManutencao,
              moeda: moeda,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ResumoCard(
                    titulo: 'Ganhos',
                    valor: moeda(ganhos),
                    icone: Icons.arrow_upward,
                    positivo: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ResumoCard(
                    titulo: 'Gastos',
                    valor: moeda(gastos),
                    icone: Icons.arrow_downward,
                    positivo: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 38,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lucro do dia',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moeda(lucro),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: lucro >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: adicionarGasto,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text(
                  'Adicionar gasto',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: abrirHistorico,
              icon: const Icon(Icons.history),
              label: const Text('Ver histórico'),
            ),
          ],
        ),
      ),
    );
  }
}

class AtendimentoCard extends StatelessWidget {
  final String titulo;
  final double valorUnitario;
  final int quantidade;
  final IconData icone;
  final VoidCallback onAdicionar;
  final VoidCallback onRemover;
  final String Function(double) moeda;

  const AtendimentoCard({
    super.key,
    required this.titulo,
    required this.valorUnitario,
    required this.quantidade,
    required this.icone,
    required this.onAdicionar,
    required this.onRemover,
    required this.moeda,
  });

  @override
  Widget build(BuildContext context) {
    final total = quantidade * valorUnitario;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              child: Icon(icone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${moeda(valorUnitario)} cada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${moeda(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemover,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantidade',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
      ),
    );
  }
}

class ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final bool positivo;

  const ResumoCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.positivo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icone,
              size: 28,
              color: positivo ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            Text(titulo),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<Map<String, dynamic>> registros = [];

  final DateFormat formatoData = DateFormat('dd/MM/yyyy');

  String moeda(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valor);
  }

  Future<void> carregar() async {
    final dados = await DatabaseHelper.instance.buscarTodos();

    setState(() {
      registros = dados;
    });
  }

  Future<void> excluir(int id) async {
    await DatabaseHelper.instance.excluir(id);
    await carregar();
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
      ),
      body: registros.isEmpty
          ? const Center(
              child: Text(
                'Nenhum registro encontrado.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];

                final tipo = registro['tipo'];
                final categoria = registro['categoria'];
                final valor = (registro['valor'] as num).toDouble();
                final data = DateTime.parse(registro['data']);

                final ganho = tipo == 'ganho';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        ganho
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                    ),
                    title: Text(
                      categoria,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(formatoData.format(data)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ganho
                              ? '+ ${moeda(valor)}'
                              : '- ${moeda(valor)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ganho
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () => excluir(registro['id']),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
