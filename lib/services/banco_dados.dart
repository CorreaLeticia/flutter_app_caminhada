
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/caminhada.dart';

class BancoDados {
  static Database? _banco;

  static Future<Database> get banco async {
    if (_banco != null) return _banco!;

    final caminho = join(
      await getDatabasesPath(),
      'caminhadas.db',
    );

    _banco = await openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE caminhadas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            latitudeInicial REAL NOT NULL,
            longitudeInicial REAL NOT NULL,
            latitudeFinal REAL NOT NULL,
            longitudeFinal REAL NOT NULL,
            distanciaKm REAL NOT NULL,
            calorias REAL NOT NULL,
            tempoMinutos INTEGER NOT NULL,
            foto TEXT,
            trajeto TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
      },
    );

    return _banco!;
  }

  static Future<int> inserir(Caminhada caminhada) async {
    final db = await banco;

    return db.insert(
      'caminhadas',
      caminhada.toMap()..remove('id'),
    );
  }

  static Future<List<Caminhada>> listar() async {
    final db = await banco;
    final resultado = await db.query(
      'caminhadas',
      orderBy: 'id DESC',
    );

    return resultado.map(Caminhada.fromMap).toList();
  }

  static Future<int> atualizar(Caminhada caminhada) async {
    final db = await banco;

    return db.update(
      'caminhadas',
      caminhada.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [caminhada.id],
    );
  }

  static Future<int> excluir(int id) async {
    final db = await banco;

    return db.delete(
      'caminhadas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}