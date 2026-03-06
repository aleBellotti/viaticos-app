import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('viaticos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movimientos_citi (
        id TEXT PRIMARY KEY,
        ac TEXT,
        fecha TEXT,
        tipo TEXT,
        saldo_pendiente REAL,
        abonado REAL,
        retirado_cajero REAL,
        efectivo REAL,
        saldo_efectivo REAL,
        fecha_retiro TEXT,
        observaciones TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE impuestos (
        id TEXT PRIMARY KEY,
        concepto TEXT,
        importe REAL,
        pagado INTEGER DEFAULT 0,
        fecha TEXT,
        observaciones TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos_mensuales (
        id TEXT PRIMARY KEY,
        tipo TEXT,
        importe REAL,
        fecha TEXT,
        observaciones TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE efectivo_casa (
        id TEXT PRIMARY KEY,
        importe REAL,
        descripcion TEXT,
        fecha TEXT,
        tipo TEXT
      )
    ''');

    // Seed initial data
    await _seedData(db);
  }

  Future _seedData(Database db) async {
    // Movimientos CITI iniciales desde el Excel
    final movimientosCiti = [
      {'id': '1', 'ac': '3432', 'fecha': '2025-11-02', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 103600.0, 'retirado_cajero': 7661.64, 'efectivo': 40000.0, 'saldo_efectivo': null, 'fecha_retiro': '2025-11-12', 'observaciones': 'z'},
      {'id': '2', 'ac': '3432', 'fecha': '2025-11-02', 'tipo': 'PEAJES', 'saldo_pendiente': null, 'abonado': 128467.96, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 20000.0, 'fecha_retiro': '2025-11-13', 'observaciones': null},
      {'id': '3', 'ac': '3432', 'fecha': '2025-11-02', 'tipo': 'SEGURO', 'saldo_pendiente': null, 'abonado': 187510.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': null, 'fecha_retiro': '2025-11-14', 'observaciones': null},
      {'id': '4', 'ac': '3840', 'fecha': '2025-10-27', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 98410.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 20000.0, 'fecha_retiro': '2025-11-18', 'observaciones': null},
      {'id': '5', 'ac': '3499', 'fecha': '2025-11-03', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 55080.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': null, 'fecha_retiro': '2025-11-19', 'observaciones': null},
      {'id': '6', 'ac': '3499', 'fecha': '2025-11-03', 'tipo': 'SEGURO', 'saldo_pendiente': null, 'abonado': 187510.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 10000.0, 'fecha_retiro': '2025-11-20', 'observaciones': null},
      {'id': '7', 'ac': '3499', 'fecha': '2025-11-03', 'tipo': 'PEAJES', 'saldo_pendiente': null, 'abonado': 115922.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 30000.0, 'fecha_retiro': '2025-11-22', 'observaciones': null},
      {'id': '8', 'ac': '6063', 'fecha': '2025-11-10', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 51520.0, 'retirado_cajero': null, 'efectivo': null, 'saldo_efectivo': 10000.0, 'fecha_retiro': '2025-11-24', 'observaciones': null},
      {'id': '9', 'ac': '6099', 'fecha': '2025-11-25', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 90800.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': null, 'fecha_retiro': '2025-11-26', 'observaciones': null},
      {'id': '10', 'ac': '3532', 'fecha': '2025-12-01', 'tipo': 'SEGURO', 'saldo_pendiente': null, 'abonado': 187510.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 10000.0, 'fecha_retiro': '2025-11-27', 'observaciones': null},
      {'id': '11', 'ac': '6120', 'fecha': '2025-12-01', 'tipo': 'PEAJES', 'saldo_pendiente': null, 'abonado': 157286.13, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 40000.0, 'fecha_retiro': '2025-11-28', 'observaciones': null},
      {'id': '12', 'ac': '6120', 'fecha': '2025-12-01', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 57200.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 4000.0, 'fecha_retiro': '2025-12-01', 'observaciones': null},
      {'id': '13', 'ac': '6103', 'fecha': '2025-12-10', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 89360.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 180000.0, 'fecha_retiro': '2025-12-02', 'observaciones': 'Garage.'},
      {'id': '14', 'ac': '6144', 'fecha': '2025-12-12', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 48890.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 100000.0, 'fecha_retiro': '2025-12-02', 'observaciones': 'Regalo Mica'},
      {'id': '15', 'ac': '6187', 'fecha': '2026-01-05', 'tipo': 'PEAJE', 'saldo_pendiente': null, 'abonado': 154356.12, 'retirado_cajero': null, 'efectivo': null, 'saldo_efectivo': 30000.0, 'fecha_retiro': '2025-12-07', 'observaciones': 'Varios'},
      {'id': '16', 'ac': '6187', 'fecha': '2026-01-05', 'tipo': 'SEGURO', 'saldo_pendiente': null, 'abonado': 187510.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 6000.0, 'fecha_retiro': '2025-12-08', 'observaciones': null},
      {'id': '17', 'ac': '6187', 'fecha': '2026-01-05', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 130480.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 110000.0, 'fecha_retiro': '2025-12-10', 'observaciones': null},
      {'id': '18', 'ac': '6224', 'fecha': '2026-01-19', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 83765.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 60000.0, 'fecha_retiro': '2025-12-15', 'observaciones': null},
      {'id': '19', 'ac': '6252', 'fecha': '2026-02-02', 'tipo': 'PEAJE', 'saldo_pendiente': null, 'abonado': 90313.51, 'retirado_cajero': 13352.0, 'efectivo': null, 'saldo_efectivo': 30000.0, 'fecha_retiro': null, 'observaciones': null},
      {'id': '20', 'ac': '6252', 'fecha': '2026-02-02', 'tipo': 'SEGURO', 'saldo_pendiente': 187510.0, 'abonado': null, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': null, 'fecha_retiro': null, 'observaciones': null},
      {'id': '21', 'ac': '3274', 'fecha': '2026-02-18', 'tipo': 'VIATICOS', 'saldo_pendiente': null, 'abonado': 87210.0, 'retirado_cajero': 40000.0, 'efectivo': 40000.0, 'saldo_efectivo': 40000.0, 'fecha_retiro': null, 'observaciones': null},
    ];

    for (final m in movimientosCiti) {
      await db.insert('movimientos_citi', {
        ...m,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Impuestos Delia
    final impuestos = [
      {'id': 'i1', 'concepto': 'Edesur', 'importe': 0.0, 'pagado': 0, 'fecha': null, 'observaciones': null},
      {'id': 'i2', 'concepto': 'Movistar', 'importe': 0.0, 'pagado': 0, 'fecha': null, 'observaciones': null},
      {'id': 'i3', 'concepto': 'Personal Flow', 'importe': 0.0, 'pagado': 0, 'fecha': null, 'observaciones': null},
      {'id': 'i4', 'concepto': 'Metrogas', 'importe': 0.0, 'pagado': 0, 'fecha': null, 'observaciones': null},
      {'id': 'i5', 'concepto': 'Italiano', 'importe': 0.0, 'pagado': 0, 'fecha': null, 'observaciones': null},
      {'id': 'i6', 'concepto': 'Deuda Ale', 'importe': 151029.26, 'pagado': 0, 'fecha': null, 'observaciones': null},
    ];

    for (final imp in impuestos) {
      await db.insert('impuestos', imp);
    }

    // Gastos mensuales
    final gastos = [
      {'id': 'g1', 'tipo': 'AMEX', 'importe': 0.0, 'fecha': null, 'observaciones': null},
      {'id': 'g2', 'tipo': 'VISA', 'importe': 0.0, 'fecha': null, 'observaciones': null},
      {'id': 'g3', 'tipo': 'FLOW', 'importe': 0.0, 'fecha': null, 'observaciones': null},
      {'id': 'g4', 'tipo': 'GARAGE', 'importe': 0.0, 'fecha': null, 'observaciones': null},
      {'id': 'g5', 'tipo': 'CLARO', 'importe': 0.0, 'fecha': null, 'observaciones': null},
    ];

    for (final g in gastos) {
      await db.insert('gastos_mensuales', g);
    }

    // Configuracion inicial
    await db.insert('configuracion', {'clave': 'saldo_tarjeta_citi', 'valor': '288127.08'});
    await db.insert('configuracion', {'clave': 'pendiente_citi', 'valor': '547020.0'});
    await db.insert('configuracion', {'clave': 'usd_banco', 'valor': '7.0'});
    await db.insert('configuracion', {'clave': 'efectivo_casa', 'valor': '60000.0'});

    // Efectivo casa
    await db.insert('efectivo_casa', {
      'id': 'ec1',
      'importe': 60000.0,
      'descripcion': 'Efectivo en casa',
      'fecha': DateTime.now().toIso8601String(),
      'tipo': 'INGRESO',
    });
  }

  // CRUD Movimientos CITI
  Future<List<Map<String, dynamic>>> getMovimientosCiti() async {
    final db = await database;
    return await db.query('movimientos_citi', orderBy: 'fecha DESC');
  }

  Future<int> insertMovimientoCiti(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('movimientos_citi', data);
  }

  Future<int> updateMovimientoCiti(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('movimientos_citi', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> deleteMovimientoCiti(String id) async {
    final db = await database;
    return await db.delete('movimientos_citi', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Impuestos
  Future<List<Map<String, dynamic>>> getImpuestos() async {
    final db = await database;
    return await db.query('impuestos');
  }

  Future<int> insertImpuesto(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('impuestos', data);
  }

  Future<int> updateImpuesto(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('impuestos', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> deleteImpuesto(String id) async {
    final db = await database;
    return await db.delete('impuestos', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Gastos Mensuales
  Future<List<Map<String, dynamic>>> getGastosMensuales() async {
    final db = await database;
    return await db.query('gastos_mensuales');
  }

  Future<int> updateGastoMensual(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('gastos_mensuales', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  // Configuracion
  Future<String?> getConfig(String clave) async {
    final db = await database;
    final result = await db.query('configuracion', where: 'clave = ?', whereArgs: [clave]);
    if (result.isNotEmpty) return result.first['valor'] as String?;
    return null;
  }

  Future<void> setConfig(String clave, String valor) async {
    final db = await database;
    await db.insert('configuracion', {'clave': clave, 'valor': valor},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Stats for dashboard
  Future<Map<String, double>> getResumenSaldos() async {
    final db = await database;

    final pendienteCiti = double.tryParse(await getConfig('pendiente_citi') ?? '0') ?? 0;
    final saldoTarjeta = double.tryParse(await getConfig('saldo_tarjeta_citi') ?? '0') ?? 0;
    final efectivoCasa = double.tryParse(await getConfig('efectivo_casa') ?? '0') ?? 0;

    final impuestos = await db.query('impuestos');
    final totalImpuestos = impuestos.fold(0.0, (sum, i) => sum + ((i['importe'] as num?) ?? 0).toDouble());

    final saldoFinal = pendienteCiti + saldoTarjeta + totalImpuestos;

    return {
      'pendiente_citi': pendienteCiti,
      'saldo_tarjeta': saldoTarjeta,
      'efectivo_casa': efectivoCasa,
      'total_impuestos': totalImpuestos,
      'saldo_final': saldoFinal,
    };
  }
}
