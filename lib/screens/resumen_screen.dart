import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final _db = DatabaseHelper.instance;
  bool _loading = true;
  Map<String, double> _saldos = {};
  Map<String, double> _porTipo = {};
  List<MovimientoCiti> _movimientos = [];
  final _fmt = NumberFormat('#,##0.00', 'es_AR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final saldos = await _db.getResumenSaldos();
    final raw = await _db.getMovimientosCiti();
    final movimientos = raw.map((m) => MovimientoCiti.fromMap(m)).toList();

    // Agrupar por tipo
    final Map<String, double> porTipo = {};
    for (final m in movimientos) {
      final t = m.tipo ?? 'OTRO';
      porTipo[t] = (porTipo[t] ?? 0) + (m.abonado ?? 0);
    }

    setState(() {
      _saldos = saldos;
      _movimientos = movimientos;
      _porTipo = porTipo;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                    _buildSectionTitle('Resumen General'),
                    const SizedBox(height: 12),
                    _buildResumenGeneral(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Distribución por Tipo'),
                    const SizedBox(height: 12),
                    _buildDistribucionPorTipo(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Últimos Movimientos'),
                    const SizedBox(height: 12),
                    _buildUltimosMovimientos(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)));
  }

  Widget _buildResumenGeneral() {
    final pendiente = _saldos['pendiente_citi'] ?? 0;
    final saldoTarjeta = _saldos['saldo_tarjeta'] ?? 0;
    final impuestos = _saldos['total_impuestos'] ?? 0;
    final efectivo = _saldos['efectivo_casa'] ?? 0;
    final total = pendiente + saldoTarjeta + impuestos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('CITI Pendiente de Pago', pendiente, const Color(0xFFE53935)),
            const Divider(),
            _summaryRow('CITI Saldo Tarjeta', saldoTarjeta, const Color(0xFF1565C0)),
            const Divider(),
            _summaryRow('Impuestos Delia', impuestos, const Color(0xFFFF8F00)),
            const Divider(),
            _summaryRow('Efectivo en Casa', efectivo, const Color(0xFF2E7D32)),
            const Divider(thickness: 2),
            _summaryRow('SALDO FINAL', total, const Color(0xFF1565C0), bold: true),
            _summaryRow('Con Efectivo', total + efectivo, const Color(0xFF1565C0), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? color : Colors.black87)),
          Text(
            '\$ ${_fmt.format(value)}',
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDistribucionPorTipo() {
    if (_porTipo.isEmpty) return const Text('Sin datos');
    final total = _porTipo.values.fold(0.0, (s, v) => s + v);

    final Map<String, Color> colors = {
      'VIATICOS': const Color(0xFF1565C0),
      'PEAJES': const Color(0xFF2E7D32),
      'PEAJE': const Color(0xFF2E7D32),
      'SEGURO': const Color(0xFFE65100),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _porTipo.entries.map((e) {
            final pct = total > 0 ? (e.value / total) : 0.0;
            final color = colors[e.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$ ${_fmt.format(e.value)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          Text('${(pct * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUltimosMovimientos() {
    final ultimos = _movimientos.take(5).toList();
    if (ultimos.isEmpty) return const Text('Sin movimientos');

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ultimos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final m = ultimos[i];
          final Map<String, Color> colors = {
            'VIATICOS': const Color(0xFF1565C0),
            'PEAJES': const Color(0xFF2E7D32),
            'PEAJE': const Color(0xFF2E7D32),
            'SEGURO': const Color(0xFFE65100),
          };
          final color = colors[m.tipo] ?? Colors.grey;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                m.tipo?.substring(0, 1) ?? '?',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('${m.tipo ?? '-'} ${m.ac != null ? "· AC ${m.ac}" : ""}',
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              m.fecha != null ? _formatDate(m.fecha!) : '-',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: m.abonado != null
                ? Text('\$ ${_fmt.format(m.abonado!)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))
                : null,
          );
        },
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}
