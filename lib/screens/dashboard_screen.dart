import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper.instance;
  Map<String, double> _saldos = {};
  bool _loading = true;
  final _fmt = NumberFormat('#,##0.00', 'es_AR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final saldos = await _db.getResumenSaldos();
    setState(() {
      _saldos = saldos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viáticos y Saldos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSaldosGrid(),
                    const SizedBox(height: 20),
                    _buildSaldoFinalCard(),
                    const SizedBox(height: 20),
                    _buildConfiguracionRapida(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Panel Principal',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        Text('Actualizado: $now', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSaldosGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildSaldoCard('CITI\nPendiente de Pago', _saldos['pendiente_citi'] ?? 0,
            const Color(0xFFE53935), Icons.credit_card),
        _buildSaldoCard('CITI\nSaldo Tarjeta', _saldos['saldo_tarjeta'] ?? 0,
            const Color(0xFF1E88E5), Icons.account_balance),
        _buildSaldoCard('Casa\nEfectivo', _saldos['efectivo_casa'] ?? 0,
            const Color(0xFF43A047), Icons.home),
        _buildSaldoCard('Delia\nImpuestos', _saldos['total_impuestos'] ?? 0,
            const Color(0xFFFF8F00), Icons.receipt_long),
      ],
    );
  }

  Widget _buildSaldoCard(String label, double value, Color color, IconData icon) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      maxLines: 2),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '\$ ${_fmt.format(value)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoFinalCard() {
    final total = (_saldos['pendiente_citi'] ?? 0) +
        (_saldos['saldo_tarjeta'] ?? 0) +
        (_saldos['total_impuestos'] ?? 0);
    final totalConEfectivo = total + (_saldos['efectivo_casa'] ?? 0);

    return Card(
      color: const Color(0xFF1565C0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SALDO FINAL',
                style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('\$ ${_fmt.format(total)}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white30, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Con Efectivo:', style: TextStyle(color: Colors.white70)),
                Text('\$ ${_fmt.format(totalConEfectivo)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracionRapida() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configuración Rápida',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildConfigTile('Efectivo en Casa', 'efectivo_casa', Icons.home, const Color(0xFF43A047)),
        const SizedBox(height: 8),
        _buildConfigTile('Saldo Tarjeta CITI', 'saldo_tarjeta_citi', Icons.credit_card, const Color(0xFF1E88E5)),
        const SizedBox(height: 8),
        _buildConfigTile('Pendiente CITI', 'pendiente_citi', Icons.warning_amber, const Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildConfigTile(String label, String key, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: FutureBuilder<String?>(
          future: _db.getConfig(key),
          builder: (ctx, snap) {
            final val = double.tryParse(snap.data ?? '0') ?? 0;
            return Text('\$ ${_fmt.format(val)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold));
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editarConfig(label, key),
        ),
      ),
    );
  }

  Future<void> _editarConfig(String label, String key) async {
    final current = await _db.getConfig(key) ?? '0';
    final ctrl = TextEditingController(text: current);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', labelText: 'Importe'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _db.setConfig(key, result);
      _loadData();
    }
  }
}
