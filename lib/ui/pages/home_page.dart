import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../atoms/custom_text_field.dart';
import '../molecules/filter_dropdown.dart';
import '../organisms/add_task_form.dart';
import '../organisms/task_list_item.dart';
import '../organisms/todo_header.dart';
import '../organisms/dialogs/confirm_delete_dialog.dart';
import '../organisms/dialogs/pick_date_type_dialog.dart';
import '../organisms/dialogs/add_task_dialog.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _storageKey = 'nantijugakelar_tasks_data';
  List<Task> _tasks = [];
  String _currentSearch = '';
  String _currentFilter = 'all'; // all, pending, completed
  bool _isAscending = true;

  final TextEditingController _taskNameCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  DateTime? _singleDate;
  bool _isEventMode = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      final now = DateTime.now();
      bool hasExpired = false;

      final loadedTasks = decoded.map((e) => Task.fromJson(e)).toList();
      final activeTasks = <Task>[];

      for (var task in loadedTasks) {
        if (task.endDate != null) {
          // Mode 3: Deadline
          final deadlineEnd = DateTime(
            task.endDate!.year,
            task.endDate!.month,
            task.endDate!.day,
            23,
            59,
            59,
          );

          if (now.isAfter(deadlineEnd)) {
            hasExpired = true;
            NotificationService().cancelReminder(task.id);
            continue; // Tugas ini dibuang dari list aktif
          }
        } else if (task.isEvent) {
          // Mode 2: Event (Catatan Masa Depan)
          final eventEnd = DateTime(
            task.startDate.year,
            task.startDate.month,
            task.startDate.day,
            23,
            59,
            59,
          );

          if (now.isAfter(eventEnd)) {
            hasExpired = true;
            NotificationService().cancelReminder(task.id);
            continue; // Tugas ini dibuang dari list aktif
          }
        }
        activeTasks.add(task);
      }

      setState(() {
        _tasks = activeTasks;
      });

      // Update penyimpanan lokal jika sapu bersih baru saja terjadi
      if (hasExpired) {
        _saveTasks();
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);

    // Perbarui Home Screen Widget setiap kali task disimpan
    await WidgetService.updateWidgetInfo(_tasks);
  }

  void _addTask() {
    final title = _taskNameCtrl.text.trim();
    if (title.isEmpty || (_selectedDateRange == null && _singleDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi detail tugas dan batas waktu.'),
        ),
      );
      return;
    }

    final DateTime startDate = _singleDate ?? _selectedDateRange!.start;
    final DateTime? endDate = _selectedDateRange?.end;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      category: _selectedCategory,
      description: _descriptionCtrl.text.trim().isNotEmpty
          ? _descriptionCtrl.text.trim()
          : null,
      isEvent: _isEventMode,
    );

    // Jadwalkan notifikasi
    if (newTask.endDate != null) {
      // Mode 3: Deadline
      NotificationService().scheduleTaskReminder(
        newTask.id,
        newTask.title,
        newTask.endDate!,
      );
      NotificationService().showImmediateNotification(
        newTask.id,
        newTask.title,
      );
    } else if (newTask.isEvent) {
      // Mode 2: Event H-7
      NotificationService().scheduleEventReminder(
        newTask.id,
        newTask.title,
        newTask.startDate,
      );
      NotificationService().showImmediateNotification(
        newTask.id,
        newTask.title,
      );
    }

    // Tampilkan Pop-up hijau di dalam aplikasi (In-App)
    // Mode 1 (Catatan Biasa): Tampil di Atas (Top)
    // Mode 2 & 3: Tampil di Bawah (Bottom)
    final snackBarMargin = newTask.endDate == null && !newTask.isEvent
        ? EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 16,
            right: 16,
          )
        : const EdgeInsets.all(16.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Tugas "${newTask.title}" berhasil disimpan!'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: snackBarMargin,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    setState(() {
      _tasks.add(newTask);
      _taskNameCtrl.clear();
      _descriptionCtrl.clear();
      _selectedDateRange = null;
      _singleDate = null;
      _selectedCategory = null;
      _isEventMode = false;
    });
    _saveTasks();
    FocusScope.of(context).unfocus();
  }

  void _toggleTask(String id) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == id);
      task.isCompleted = !task.isCompleted;

      if (task.endDate != null) {
        if (task.isCompleted) {
          NotificationService().cancelReminder(id);
        } else {
          NotificationService().scheduleTaskReminder(
            task.id,
            task.title,
            task.endDate!,
          );
        }
      }
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    NotificationService().cancelReminder(id);
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _saveTasks();
  }

  void _confirmDeleteTask(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        title: 'Hapus Tugas?',
        message: 'Apakah Anda yakin ingin menghapus tugas "$title"?',
        icon: Icons.delete_outline_rounded,
        onConfirm: () => _deleteTask(id),
      ),
    );
  }

  void _deleteAll() {
    if (_tasks.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        title: 'Konfirmasi Hapus',
        message:
            'Apakah Anda yakin ingin menghapus semua tugas dalam daftar ini? Tindakan ini tidak dapat dibatalkan.',
        confirmLabel: 'Hapus Semua',
        onConfirm: () {
          setState(() {
            _tasks.clear();
          });
          _saveTasks();
        },
      ),
    );
  }

  Future<bool> _pickDate() async {
    final int? choice = await showDialog<int>(
      context: context,
      builder: (ctx) => const PickDateTypeDialog(),
    );

    if (choice == null) return false;

    if (choice == 1) {
      final date = await showDatePicker(
        context: context,
        initialDate: _singleDate ?? DateTime.now(),
        firstDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        setState(() {
          _singleDate = date;
          _selectedDateRange = null; // Clear range
          _isEventMode = false;
        });
        return true;
      }
      return false;
    } else if (choice == 2) {
      final date = await showDatePicker(
        context: context,
        initialDate: _singleDate ?? DateTime.now(),
        firstDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        setState(() {
          _singleDate = date;
          _selectedDateRange = null; // Clear range
          _isEventMode = true;
        });
        return true;
      }
      return false;
    } else if (choice == 3) {
      final dateRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        lastDate: DateTime(2100),
        initialDateRange:
            _selectedDateRange ??
            DateTimeRange(
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(days: 1)),
            ),
      );
      if (dateRange != null) {
        setState(() {
          _selectedDateRange = dateRange;
          _singleDate = null; // Clear single
          _isEventMode = false;
        });
        return true;
      }
      return false;
    }
    return false;
  }

  Future<void> _startAddFlow() async {
    final title = _taskNameCtrl.text.trim();
    if (title.isEmpty) return;

    final picked = await _pickDate();
    if (!picked) return; // if user cancels or doesn't pick

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AddTaskDialog(
          taskName: title,
          selectedDateRange: _selectedDateRange,
          singleDate: _singleDate,
          initialCategory: _selectedCategory,
          descriptionCtrl: _descriptionCtrl,
          onCategoryChanged: (category) {
            _selectedCategory = category;
          },
          onSave: () => _addTask(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.isCompleted).length;
    final pending = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    // Hitung selesai dalam seminggu
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyCompleted = _tasks
        .where((t) => t.isCompleted && t.createdAt.isAfter(oneWeekAgo))
        .length;

    // Filter and Sort
    List<Task> filteredTasks = _tasks.where((t) {
      final matchSearch = t.title.toLowerCase().contains(_currentSearch);
      final matchFilter = _currentFilter == 'all'
          ? true
          : _currentFilter == 'completed'
          ? t.isCompleted
          : !t.isCompleted;
      return matchSearch && matchFilter;
    }).toList();

    filteredTasks.sort((a, b) {
      final t1 =
          a.endDate?.millisecondsSinceEpoch ??
          a.startDate.millisecondsSinceEpoch;
      final t2 =
          b.endDate?.millisecondsSinceEpoch ??
          b.startDate.millisecondsSinceEpoch;
      return _isAscending ? t1.compareTo(t2) : t2.compareTo(t1);
    });

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 12,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // Max width for tablet viewing
          child: Column(
            children: [
              TodoHeader(
                total: total,
                completed: completed,
                pending: pending,
                progress: progress,
                weeklyCompleted: weeklyCompleted,
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AddTaskForm(
                          controller: _taskNameCtrl,
                          onAddDialog: _startAddFlow,
                        ),
                        const SizedBox(height: 24),
                        _buildToolbar(),
                        const SizedBox(height: 16),
                        _buildListHeaders(),
                        const SizedBox(height: 8),
                        _buildTaskList(filteredTasks),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _searchCtrl,
            hintText: 'Cari tugas...',
            onChanged: (val) {
              setState(() {
                _currentSearch = val.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        FilterDropdown(
          currentValue: _currentFilter,
          onChanged: (val) {
            if (val != null) setState(() => _currentFilter = val);
          },
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isAscending = !_isAscending;
            });
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isAscending ? 'Urutkan ↓' : 'Urutkan ↑',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeaders() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Semua Tugas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        InkWell(
          onTap: _deleteAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Hapus Semua',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> filteredTasks) {
    if (filteredTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: const Text(
          'Tidak ada tugas ditemukan. Semua sudah beres!',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: filteredTasks
          .map(
            (t) => TaskListItem(
              task: t,
              onToggle: (_) => _toggleTask(t.id),
              onDelete: () => _confirmDeleteTask(t.id, t.title),
            ),
          )
          .toList(),
    );
  }
}
