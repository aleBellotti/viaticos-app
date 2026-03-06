import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class CitiScreen extends StatefulWidget {
  const CitiScreen({super.key});

  @override
  State<CitiScreen> createState() => _CitiScreenState();
}

class _CitiScreenState extends State<CitiScreen> {
  final _db = DatabaseHelper.instance;
  List<MovimientoCiti> _movimientos = [];
  bool _loading = true;
  String _filtroTipo = 'TODOS';
  final _fmt = NumberFormat('#,##0.00', 'es_AR');

  final _tipos = ['TODOS', 'VIATICOS', 'PEAJES', 'SEGURO', 'PEAJE'];
  final Map<String, Color> _tipoColors = {
    'VIATICOS': const Color(0xFF1565C0),
    'PEAJES': const Color(0xFF2E7D32),
    'PEAJE': const Color(0xFF2E7D32),
    'SEGURO': const Color(0xFFE65100),
    'TODOS': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final raw = await _db.getMovimientosCiti();
    setState(() {
      _movimientos = raw.map((m) => MovimientoCiti.fromMap(m)).toList();
      _loading = false;
    });
  }

  List<MovimientoCiti> get _filtrados {
    if (_filtroTipo == 'TODOS') return _movimientos;
    return _movimientos.where((m) => m.tipo == _filtroTipo).toList();
  }

  double get _totalAbonado =>
      _filtrados.fold(0, (s, m) => s + (m.abonado ?? 0));
  double get _totalSaldoPendiente =>
      _filtrados.fold(0, (s, m) => s + (m.saldoPendiente ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos CITI'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildResumenBanner(),
                _buildFiltros(),
                Expanded(
                  child: _filtrados.isEmpty
                      ? const Center(child: Text('No hay movimientos'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _filtrados.length,
                          itemBuilder: (ctx, i) => _buildMovimientoCard(_filtrados[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumenBanner() {
    return Container(
      color: const Color(0xFF1565C0).withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip('Total Abonado', _totalAbonado, const Color(0xFF1565C0)),
          _buildStatChip('Pendiente', _totalSaldoPendiente, const Color(0xFFE53935)),
          _buildStatChip('Registros', _filtrados.length.toDouble(), Colors.grey, isCount: true),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, double value, Color color, {bool isCount = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          isCount ? '${value.toInt()}' : '\$ ${_fmt.format(value)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _tipos.map((tipo) {
          final selected = _filtroTipo == tipo;
          final color = _tipoColors[tipo] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tipo),
              selected: selected,
              onSelected: (_) => setState(() => _filtroTipo = tipo),
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMovimientoCard(MovimientoCiti m) {
    final color = _tipoColors[m.tipo] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalle(m),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m.tipo ?? '-',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (m.ac != null)
                    Text('AC: ${m.ac}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  Text(
                    m.fecha != null ? _formatDate(m.fecha!) : '-',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (action) {
                      if (action == 'edit') _mostrarFormulario(context, movimiento: m);
                      if (action == 'delete') _confirmarEliminar(m);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildDataCell('Abonado', m.abonado, const Color(0xFF1565C0)),
                  _buildDataCell('Cajero', m.retiradoCajero, const Color(0xFF2E7D32)),
                  _buildDataCell('Efectivo', m.efectivo, const Color(0xFF6A1B9A)),
                ],
              ),
              if (m.saldoPendiente != null || m.saldoEfectivo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      if (m.saldoPendiente != null)
                        _buildDataCell('Pendiente', m.saldoPendiente, const Color(0xFFE53935)),
                      if (m.saldoEfectivo != null)
                        _buildDataCell('Sdo. Efec.', m.saldoEfectivo, const Color(0xFFFF8F00)),
                    ],
                  ),
                ),
              if (m.observaciones != null && m.observaciones!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(m.observaciones!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String label, double? value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value != null ? '\$ ${_fmt.format(value)}' : '-',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('dd/MM/yy').format(d);
    } catch (_) {
      return date;
    }
  }

  void _mostrarDetalle(MovimientoCiti m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Detalle del Movimiento',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('AC', m.ac ?? '-'),
            _detailRow('Tipo', m.tipo ?? '-'),
            _detailRow('Fecha', m.fecha != null ? _formatDate(m.fecha!) : '-'),
            _detailRow('Abonado', m.abonado != null ? '\$ ${_fmt.format(m.abonado!)}' : '-'),
            _detailRow('Retirado Cajero', m.retiradoCajero != null ? '\$ ${_fmt.format(m.retiradoCajero!)}' : '-'),
            _detailRow('Efectivo', m.efectivo != null ? '\$ ${_fmt.format(m.efectivo!)}' : '-'),
            _detailRow('Saldo Efectivo', m.saldoEfectivo != null ? '\$ ${_fmt.format(m.saldoEfectivo!)}' : '-'),
            _detailRow('Saldo Pendiente', m.saldoPendiente != null ? '\$ ${_fmt.format(m.saldoPendiente!)}' : '-'),
            _detailRow('Fecha Retiro', m.fechaRetiro != null ? _formatDate(m.fechaRetiro!) : '-'),
            _detailRow('Observaciones', m.observaciones ?? '-'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mostrarFormulario(context, movimiento: m);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmarEliminar(m);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, {MovimientoCiti? movimiento}) async {
    final isEdit = movimiento != null;
    final acCtrl = TextEditingController(text: movimiento?.ac ?? '');
    final abonadoCtrl = TextEditingController(text: movimiento?.abonado?.toString() ?? '');
    final cajeroCtrl = TextEditingController(text: movimiento?.retiradoCajero?.toString() ?? '');
    final efectivoCtrl = TextEditingController(text: movimiento?.efectivo?.toString() ?? '');
    final saldoEfCtrl = TextEditingController(text: movimiento?.saldoEfectivo?.toString() ?? '');
    final saldoPendCtrl = TextEditingController(text: movimiento?.saldoPendiente?.toString() ?? '');
    final obsCtrl = TextEditingController(text: movimiento?.observaciones ?? '');
    String tipo = movimiento?.tipo ?? 'VIATICOS';
    String? fecha = movimiento?.fecha;
    String? fechaRetiro = movimiento?.fechaRetiro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isEdit ? 'Editar Movimiento' : 'Nuevo Movimiento',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: acCtrl,
                        decoration: const InputDecoration(labelText: 'AC', hintText: 'Ej: 6187'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: tipo,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: ['VIATICOS', 'PEAJES', 'PEAJE', 'SEGURO']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setModalState(() => tipo = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _datePickerField(ctx, 'Fecha', fecha, (d) => setModalState(() => fecha = d))),
                    const SizedBox(width: 12),
                    Expanded(child: _datePickerField(ctx, 'Fecha Retiro', fechaRetiro, (d) => setModalState(() => fechaRetiro = d))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numberField(abonadoCtrl, 'Abonado')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(cajeroCtrl, 'Retirado Cajero')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numberField(efectivoCtrl, 'Efectivo')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(saldoEfCtrl, 'Saldo Efectivo')),
                  ],
                ),
                const SizedBox(height: 12),
                _numberField(saldoPendCtrl, 'Saldo Pendiente'),
                const SizedBox(height: 12),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final data = {
                        'id': movimiento?.id ?? const Uuid().v4(),
                        'ac': acCtrl.text.isEmpty ? null : acCtrl.text,
                        'fecha': fecha,
                        'tipo': tipo,
                        'saldo_pendiente': double.tryParse(saldoPendCtrl.text),
                        'abonado': double.tryParse(abonadoCtrl.text),
                        'retirado_cajero': double.tryParse(cajeroCtrl.text),
                        'efectivo': double.tryParse(efectivoCtrl.text),
                        'saldo_efectivo': double.tryParse(saldoEfCtrl.text),
                        'fecha_retiro': fechaRetiro,
                        'observaciones': obsCtrl.text.isEmpty ? null : obsCtrl.text,
                        'created_at': DateTime.now().toIso8601String(),
                      };
                      if (isEdit) {
                        await _db.updateMovimientoCiti(data);
                      } else {
                        await _db.insertMovimientoCiti(data);
                      }
                      if (context.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    child: Text(isEdit ? 'Actualizar' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, prefixText: '\$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _datePickerField(BuildContext ctx, String label, String? current, Function(String?) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: current != null ? DateTime.tryParse(current) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().split('T').first);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          current != null ? _formatDate(current) : 'Seleccionar',
          style: TextStyle(color: current != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(MovimientoCiti m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text('¿Eliminar movimiento de tipo ${m.tipo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteMovimientoCiti(m.id);
      _loadData();
    }
  }
}
