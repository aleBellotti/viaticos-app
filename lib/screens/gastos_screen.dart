import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _db = DatabaseHelper.instance;
  List<GastoMensual> _gastos = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,##0.00', 'es_AR');

  final Map<String, IconData> _tipoIcons = {
    'AMEX': Icons.credit_card,
    'VISA': Icons.credit_card,
    'FLOW': Icons.wifi,
    'GARAGE': Icons.garage,
    'CLARO': Icons.phone_android,
  };

  final Map<String, Color> _tipoColors = {
    'AMEX': const Color(0xFF1565C0),
    'VISA': const Color(0xFF6A1B9A),
    'FLOW': const Color(0xFF00838F),
    'GARAGE': const Color(0xFF558B2F),
    'CLARO': const Color(0xFFE53935),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final raw = await _db.getGastosMensuales();
    setState(() {
      _gastos = raw.map((g) => GastoMensual.fromMap(g)).toList();
      _loading = false;
    });
  }

  double get _total => _gastos.fold(0, (s, g) => s + g.importe);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Mensuales'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTotalBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _gastos.length,
                    itemBuilder: (ctx, i) => _buildGastoCard(_gastos[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF1565C0).withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Gastos Mensuales',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text('\$ ${_fmt.format(_total)}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGastoCard(GastoMensual gasto) {
    final color = _tipoColors[gasto.tipo] ?? Colors.grey;
    final icon = _tipoIcons[gasto.tipo] ?? Icons.account_balance_wallet;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gasto.tipo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (gasto.observaciones != null && gasto.observaciones!.isNotEmpty)
                    Text(gasto.observaciones!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _editarImporte(gasto),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gasto.importe > 0 ? '\$ ${_fmt.format(gasto.importe)}' : 'Sin importe',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 14, color: color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarImporte(GastoMensual gasto) async {
    final ctrl = TextEditingController(
        text: gasto.importe > 0 ? gasto.importe.toString() : '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${gasto.tipo}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', labelText: 'Importe mensual'),
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
      gasto.importe = double.tryParse(result) ?? 0;
      await _db.updateGastoMensual(gasto.toMap());
      _loadData();
    }
  }
}
