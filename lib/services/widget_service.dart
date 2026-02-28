import 'package:home_widget/home_widget.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String appGroupId = 'nantijugakelar_group';
  static const String androidWidgetName = 'TodoWidgetProvider';

  static Future<void> updateWidgetInfo(List<Task> tasks) async {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    pendingTasks.sort((a, b) {
      final aDate = a.endDate ?? a.startDate;
      final bDate = b.endDate ?? b.startDate;
      return aDate.compareTo(bDate);
    });

    // Ambil maksimal 3 tugas teratas yang belum selesai
    final tasksToShow = pendingTasks.take(3).toList();

    // Simpan judul-judul tugas ke HomeWidget Preferences
    String taskTitles = "";
    if (tasksToShow.isEmpty) {
      taskTitles = "Semua tugas beres! 🎉";
    } else {
      taskTitles = tasksToShow
          .map((t) {
            String date;
            if (t.endDate != null) {
              date = DateFormat('dd/MM').format(t.endDate!);
            } else {
              date = DateFormat('dd/MM').format(t.startDate);
            }
            return "• ${t.title} ($date)";
          })
          .join("\n");
    }

    await HomeWidget.saveWidgetData<String>(
      'pending_tasks_count',
      '${pendingTasks.length} Tertunda',
    );
    await HomeWidget.saveWidgetData<String>('tasks_list', taskTitles);

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }
}
