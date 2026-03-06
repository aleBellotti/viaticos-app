class MovimientoCiti {
  final String id;
  final String? ac;
  final String? fecha;
  final String? tipo;
  final double? saldoPendiente;
  final double? abonado;
  final double? retiradoCajero;
  final double? efectivo;
  final double? saldoEfectivo;
  final String? fechaRetiro;
  final String? observaciones;
  final String? createdAt;

  MovimientoCiti({
    required this.id,
    this.ac,
    this.fecha,
    this.tipo,
    this.saldoPendiente,
    this.abonado,
    this.retiradoCajero,
    this.efectivo,
    this.saldoEfectivo,
    this.fechaRetiro,
    this.observaciones,
    this.createdAt,
  });

  factory MovimientoCiti.fromMap(Map<String, dynamic> map) {
    return MovimientoCiti(
      id: map['id'] ?? '',
      ac: map['ac'],
      fecha: map['fecha'],
      tipo: map['tipo'],
      saldoPendiente: (map['saldo_pendiente'] as num?)?.toDouble(),
      abonado: (map['abonado'] as num?)?.toDouble(),
      retiradoCajero: (map['retirado_cajero'] as num?)?.toDouble(),
      efectivo: (map['efectivo'] as num?)?.toDouble(),
      saldoEfectivo: (map['saldo_efectivo'] as num?)?.toDouble(),
      fechaRetiro: map['fecha_retiro'],
      observaciones: map['observaciones'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ac': ac,
      'fecha': fecha,
      'tipo': tipo,
      'saldo_pendiente': saldoPendiente,
      'abonado': abonado,
      'retirado_cajero': retiradoCajero,
      'efectivo': efectivo,
      'saldo_efectivo': saldoEfectivo,
      'fecha_retiro': fechaRetiro,
      'observaciones': observaciones,
      'created_at': createdAt,
    };
  }
}

class Impuesto {
  final String id;
  final String concepto;
  double importe;
  bool pagado;
  final String? fecha;
  final String? observaciones;

  Impuesto({
    required this.id,
    required this.concepto,
    required this.importe,
    this.pagado = false,
    this.fecha,
    this.observaciones,
  });

  factory Impuesto.fromMap(Map<String, dynamic> map) {
    return Impuesto(
      id: map['id'] ?? '',
      concepto: map['concepto'] ?? '',
      importe: (map['importe'] as num?)?.toDouble() ?? 0,
      pagado: (map['pagado'] as int?) == 1,
      fecha: map['fecha'],
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'importe': importe,
      'pagado': pagado ? 1 : 0,
      'fecha': fecha,
      'observaciones': observaciones,
    };
  }
}

class GastoMensual {
  final String id;
  final String tipo;
  double importe;
  final String? fecha;
  final String? observaciones;

  GastoMensual({
    required this.id,
    required this.tipo,
    required this.importe,
    this.fecha,
    this.observaciones,
  });

  factory GastoMensual.fromMap(Map<String, dynamic> map) {
    return GastoMensual(
      id: map['id'] ?? '',
      tipo: map['tipo'] ?? '',
      importe: (map['importe'] as num?)?.toDouble() ?? 0,
      fecha: map['fecha'],
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'importe': importe,
      'fecha': fecha,
      'observaciones': observaciones,
    };
  }
}
