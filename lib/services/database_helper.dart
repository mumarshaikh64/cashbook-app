import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/book.dart';
import '../models/party.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // BOOK OPERATIONS
  Future<int> insertBook(BookModel book) async {
    final db = await instance.database;
    return await db.insert('books', book.toMap());
  }

  Future<List<BookModel>> getAllBooks() async {
    final db = await instance.database;
    const query = '''
      SELECT *, 
      (SELECT SUM(amount) FROM transactions WHERE transactions.bookId = books.id AND transactions.type = 0) as cashIn,
      (SELECT SUM(amount) FROM transactions WHERE transactions.bookId = books.id AND transactions.type = 1) as cashOut
      FROM books
      ORDER BY createdAt DESC
    ''';
    final result = await db.rawQuery(query);
    return result.map((json) => BookModel.fromMap(json)).toList();
  }

  Future<int> deleteBook(int id) async {
    final db = await instance.database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBookName(int id, String newName) async {
    final db = await instance.database;
    return await db.update('books', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cashbook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS books (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, createdAt TEXT NOT NULL)');
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN bookId INTEGER NOT NULL DEFAULT 0');
      } catch (e) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN attachmentPath TEXT');
      } catch (e) {}
      await db.execute('CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
      final commonCategories = ['Salary', 'Rent', 'Food', 'Fuel', 'Shopping', 'Business', 'Travel', 'Medical', 'Other'];
      for (var category in commonCategories) {
        await db.insert('categories', {'name': category}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN partyName TEXT');
      } catch (e) {}
    }
    if (oldVersion < 5) {
      await db.execute('CREATE TABLE IF NOT EXISTS parties (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
      // Legacy data migration: Insert existing unique partyNames into parties table
      try {
        final existingParties = await db.rawQuery('SELECT DISTINCT partyName FROM transactions WHERE partyName IS NOT NULL AND partyName != ""');
        for (var p in existingParties) {
          await db.insert('parties', {'name': p['partyName']}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN paymentMode TEXT NOT NULL DEFAULT "Cash"');
        await db.execute('ALTER TABLE transactions ADD COLUMN reference TEXT');
      } catch (e) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN customFields TEXT');
      } catch (e) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE parties ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE parties ADD COLUMN address TEXT');
      } catch (e) {}
    }
  }

  Future _createDB(Database db, int version) async {
    const booksTable = '''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''';
    await db.execute(booksTable);

    const transactionTable = '''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        attachmentPath TEXT,
        partyName TEXT,
        paymentMode TEXT NOT NULL DEFAULT 'Cash',
        reference TEXT,
        customFields TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''';
    await db.execute(transactionTable);

    const categoryTable = '''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''';
    await db.execute(categoryTable);
    
    await db.execute('CREATE TABLE parties (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, phone TEXT, address TEXT)');
    
    final commonCategories = ['Salary', 'Rent', 'Food', 'Fuel', 'Shopping', 'Business', 'Travel', 'Medical', 'Other'];
    for (var category in commonCategories) {
      await db.insert('categories', {'name': category});
    }
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    if (transaction.partyName != null && transaction.partyName!.isNotEmpty) {
      await insertParty(transaction.partyName!);
    }
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    if (transaction.partyName != null && transaction.partyName!.isNotEmpty) {
      await insertParty(transaction.partyName!);
    }
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<List<TransactionModel>> getTransactionsByBook(int bookId) async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // CATEGORY OPERATIONS
  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> insertCategory(String name) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // PARTY OPERATIONS
  Future<List<String>> getAllParties() async {
    final db = await instance.database;
    final result = await db.query('parties');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> insertParty(String name) async {
    final db = await instance.database;
    return await db.insert('parties', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<PartyModel>> getAllPartiesWithDetails() async {
    final db = await instance.database;
    const query = '''
      SELECT p.*,
      (SELECT SUM(amount) FROM transactions WHERE transactions.partyName = p.name AND transactions.type = 0) as cashIn,
      (SELECT SUM(amount) FROM transactions WHERE transactions.partyName = p.name AND transactions.type = 1) as cashOut
      FROM parties p
      ORDER BY p.name ASC
    ''';
    final result = await db.rawQuery(query);
    return result.map((json) {
      return PartyModel(
        id: json['id'] as int?,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        cashIn: (json['cashIn'] as num? ?? 0.0).toDouble(),
        cashOut: (json['cashOut'] as num? ?? 0.0).toDouble(),
      );
    }).toList();
  }

  Future<int> insertPartyModel(PartyModel party) async {
    final db = await instance.database;
    return await db.insert('parties', party.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updatePartyModel(PartyModel party) async {
    final db = await instance.database;
    return await db.update('parties', party.toMap(), where: 'id = ?', whereArgs: [party.id]);
  }

  Future<int> deleteParty(int id) async {
    final db = await instance.database;
    return await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalCashIn(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(amount) FROM transactions WHERE bookId = ? AND type = ?', [bookId, TransactionType.cashIn.index]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalCashOut(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(amount) FROM transactions WHERE bookId = ? AND type = ?', [bookId, TransactionType.cashOut.index]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'isSynced = ?', whereArgs: [0]);
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
