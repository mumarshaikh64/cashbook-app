import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/book.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<BookModel> _books = [];
  BookModel? _currentBook;
  List<TransactionModel> _transactions = [];
  List<String> _categories = [];
  List<String> _parties = [];
  double _totalCashIn = 0.0;
  double _totalCashOut = 0.0;
  bool _isLoading = false;

  List<BookModel> get books => _books;
  BookModel? get currentBook => _currentBook;
  List<TransactionModel> get transactions => _transactions;
  List<String> get categories => _categories;
  List<String> get parties => _parties;
  double get totalCashIn => _totalCashIn;
  double get totalCashOut => _totalCashOut;
  double get balance => _totalCashIn - _totalCashOut;
  bool get isLoading => _isLoading;

  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();
    _books = await DatabaseHelper.instance.getAllBooks();
    if (_books.isNotEmpty && _currentBook == null) {
      _currentBook = _books.first;
    }
    await fetchCategories();
    await fetchParties();
    await fetchTransactions();
  }

  Future<void> createBook(String name) async {
    final book = BookModel(name: name, createdAt: DateTime.now());
    final id = await DatabaseHelper.instance.insertBook(book);
    _currentBook = BookModel(id: id, name: name, createdAt: book.createdAt);
    await fetchBooks();
  }

  Future<void> setCurrentBook(BookModel book) async {
    _currentBook = book;
    await fetchTransactions();
  }

  Future<void> deleteBook(int id) async {
    await DatabaseHelper.instance.deleteBook(id);
    if (_currentBook?.id == id) _currentBook = null;
    await fetchBooks();
  }

  Future<void> renameBook(int id, String newName) async {
    await DatabaseHelper.instance.updateBookName(id, newName);
    await fetchBooks();
  }

  Future<void> fetchTransactions() async {
    if (_currentBook == null) {
      _transactions = [];
      _totalCashIn = 0;
      _totalCashOut = 0;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final bookId = _currentBook!.id!;
    _transactions = await DatabaseHelper.instance.getTransactionsByBook(bookId);
    _totalCashIn = await DatabaseHelper.instance.getTotalCashIn(bookId);
    _totalCashOut = await DatabaseHelper.instance.getTotalCashOut(bookId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _categories = await DatabaseHelper.instance.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await DatabaseHelper.instance.insertCategory(name);
    await fetchCategories();
  }

  Future<void> fetchParties() async {
    _parties = await DatabaseHelper.instance.getAllParties();
    notifyListeners();
  }

  Future<void> addParty(String name) async {
    await DatabaseHelper.instance.insertParty(name);
    await fetchParties();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await fetchTransactions();
    await fetchParties(); // Refresh parties list
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await fetchTransactions();
    await fetchParties();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await fetchTransactions();
  }
}
