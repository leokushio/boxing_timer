import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = 'workouts.db';

  static final table = 'my_table';

  static final columnId = 'id';
  static final columnName = 'name';
  static final columnRoundTime = 'roundtime';
  static final columnRestTime = 'resttime';
  static final columnRounds = 'rounds';

  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  initDatabase() async {
    Directory documentsdirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsdirectory.path, _databaseName);

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnRoundTime INTERGER,
        $columnRestTime INTERGER,
        $columnRounds INTERGER
      )
    ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database? db = await instance.database;
    return await db!.query(table);
  }

  Future<int> deletedata(int id) async {
    Database? db = await instance.database;
    var res = await db!.delete(table, where: 'id= ?', whereArgs: [id]);
    return res;
  }
}
