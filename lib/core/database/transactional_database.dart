import 'package:sqflite/sqflite.dart';

abstract interface class TransactionalDatabase {
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
