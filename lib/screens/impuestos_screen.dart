import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ImpuestosScreen extends StatefulWidget {
  const ImpuestosScreen({super.key});

  @override
  State<ImpuestosScreen> createState() => _ImpuestosScreenState();
}

class _ImpuestosScreenState extends State<ImpuestosScreen> {
  final _db = DatabaseHelper.instance;
  List<Impuesto> _impuestos = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,##0.00', 'es_AR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final raw = await _db.getImpuestos();
    setState(() {
      _impuestos = raw.map((i) => Impuesto.fromMap(i)).toList();
      _loading = false;
    });
  }

  double get _totalImpuestos => _impuestos.fold(0, (s, i) => s + i.importe);
  double get _totalPagado =>
      _impuestos.where((i) => i.pagado).fold(0, (s, i) => s + i.importe);
  double get _totalPendiente =>
      _impuestos.where((i) => !i.pagado).fold(0, (s, i) => s + i.importe);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delia - Impuestos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildResumen(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _impuestos.length,
                    itemBuilder: (ctx, i) => _buildImpuestoCard(_impuestos[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFF8F00).withOpacity(0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _chip('Total', _totalImpuestos, const Color(0xFFFF8F00)),
          _chip('Pagado', _totalPagado, const Color(0xFF2E7D32)),
          _chip('Pendiente', _totalPendiente, const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _chip(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text('\$ ${_fmt.format(value)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildImpuestoCard(Impuesto imp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: imp.pagado
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : const Color(0xFFE53935).withOpacity(0.1),
          child: Icon(
            imp.pagado ? Icons.check_circle : Icons.pending,
            color: imp.pagado ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          ),
        ),
        title: Text(imp.concepto, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          imp.importe > 0 ? '\$ ${_fmt.format(imp.importe)}' : 'Sin importe',
          style: TextStyle(
            color: imp.importe > 0 ? const Color(0xFFFF8F00) : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: imp.pagado,
              onChanged: (v) async {
                imp.pagado = v;
                await _db.updateImpuesto(imp.toMap());
                _loadData();
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') _mostrarFormulario(context, impuesto: imp);
                if (action == 'delete') _confirmarEliminar(imp);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, {Impuesto? impuesto}) async {
    final isEdit = impuesto != null;
    final conceptoCtrl = TextEditingController(text: impuesto?.concepto ?? '');
    final importeCtrl = TextEditingController(
        text: impuesto?.importe != null && impuesto!.importe > 0 ? impuesto.importe.toString() : '');
    final obsCtrl = TextEditingController(text: impuesto?.observaciones ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Editar Impuesto' : 'Nuevo Impuesto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: conceptoCtrl,
              decoration: const InputDecoration(labelText: 'Concepto', hintText: 'Ej: Edesur'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: importeCtrl,
              decoration: const InputDecoration(labelText: 'Importe', prefixText: '\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (conceptoCtrl.text.isEmpty) return;
                  final data = {
                    'id': impuesto?.id ?? const Uuid().v4(),
                    'concepto': conceptoCtrl.text,
                    'importe': double.tryParse(importeCtrl.text) ?? 0,
                    'pagado': impuesto?.pagado == true ? 1 : 0,
                    'fecha': null,
                    'observaciones': obsCtrl.text.isEmpty ? null : obsCtrl.text,
                  };
                  if (isEdit) {
                    await _db.updateImpuesto(data);
                  } else {
                    await _db.insertImpuesto(data);
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
    );
  }

  Future<void> _confirmarEliminar(Impuesto imp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar impuesto'),
        content: Text('¿Eliminar "${imp.concepto}"?'),
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
      await _db.deleteImpuesto(imp.id);
      _loadData();
    }
  }
}
