import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rota_model.dart';  // if you're in a subfolder one level down
 // Import your model

class RouteDatabase {
  static final RouteDatabase instance = RouteDatabase._init();
  static Database? _database;

  RouteDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('routes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        partida TEXT NOT NULL,
        destino TEXT NOT NULL
      )
    ''');
  }

  Future<RotaModel> create(RotaModel route) async {
    final db = await instance.database;
    final id = await db.insert('routes', route.toMap());
    return route.copyWith(id: id);
  }

  Future<List<RotaModel>> readAllRoutes() async {
    final db = await instance.database;
    final result = await db.query('routes');
    return result.map((json) => RotaModel.fromMap(json)).toList();
  }

  Future<int> update(RotaModel route) async {
    final db = await instance.database;
    return db.update(
      'routes',
      route.toMap(),
      where: 'id = ?',
      whereArgs: [route.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
