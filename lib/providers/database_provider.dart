import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseHelper.instance.database;
});
