import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

// Conditional imports for web vs native file saving
import 'excel_export_stub.dart'
    if (dart.library.html) 'excel_export_web.dart'
    if (dart.library.io) 'excel_export_native.dart' as platform;

class ExcelExporter {
  static Future<void> exportTasks(List<Task> tasks) async {
    final excel = Excel.createExcel();

    // Task sheet
    final taskSheet = excel['タスク一覧'];
    excel.delete('Sheet1');

    // Header row
    taskSheet.appendRow([
      TextCellValue('タスク名'),
      TextCellValue('説明'),
      TextCellValue('期限'),
      TextCellValue('見込み時間'),
      TextCellValue('優先度'),
      TextCellValue('タグ'),
      TextCellValue('完了'),
      TextCellValue('完了日'),
      TextCellValue('作成日'),
    ]);

    // Style header
    for (int col = 0; col < 9; col++) {
      taskSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#6C63FF'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd');

    for (final task in tasks) {
      taskSheet.appendRow([
        TextCellValue(task.title),
        TextCellValue(task.description ?? ''),
        TextCellValue(
            task.dueDate != null ? dateFormat.format(task.dueDate!) : ''),
        TextCellValue(task.estimatedTimeLabel ?? ''),
        TextCellValue(task.priorityLabel),
        TextCellValue(task.tags.map((t) => t.name).join(', ')),
        TextCellValue(task.isCompleted ? '完了' : '未完了'),
        TextCellValue(task.completedAt != null
            ? dateFormat.format(task.completedAt!)
            : ''),
        TextCellValue(dateFormat.format(task.createdAt)),
      ]);

      // Add subtasks indented
      for (final subtask in task.subtasks) {
        taskSheet.appendRow([
          TextCellValue('  └ ${subtask.title}'),
          TextCellValue(''),
          TextCellValue(subtask.dueDate != null
              ? dateFormat.format(subtask.dueDate!)
              : ''),
          TextCellValue(''),
          TextCellValue(subtask.priorityLabel),
          TextCellValue(subtask.tags.map((t) => t.name).join(', ')),
          TextCellValue(subtask.isCompleted ? '完了' : '未完了'),
          TextCellValue(subtask.completedAt != null
              ? dateFormat.format(subtask.completedAt!)
              : ''),
          TextCellValue(dateFormat.format(subtask.createdAt)),
        ]);
      }
    }

    // Auto-fit columns
    for (int col = 0; col < 9; col++) {
      taskSheet.setColumnWidth(col, 20);
    }
    taskSheet.setColumnWidth(0, 30);

    final bytes = excel.save();
    if (bytes == null) return;

    final fileName =
        'タスク一覧_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      platform.saveFileWeb(Uint8List.fromList(bytes), fileName);
    } else {
      await platform.saveFileNative(Uint8List.fromList(bytes), fileName);
    }
  }
}
