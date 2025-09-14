import 'dart:math';
import 'package:task_tracker/models/category.dart';
import 'package:task_tracker/services/database_helper.dart';

String _genCategoryId() {
  final rnd = Random();
  return 'cat_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1 << 32).toRadixString(16)}';
}

class CategoryService {
  Future<List<Category>> getCategories() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => Category.fromJson(r)).toList();
  }

  Future<Category> addCategory(String name, {int? colorValue}) async {
    final db = await DatabaseHelper().database;
    final category = Category(id: _genCategoryId(), name: name, colorValue: colorValue);
    await db.insert('categories', category.toJson());
    return category;
  }

  Future<void> deleteCategory(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
