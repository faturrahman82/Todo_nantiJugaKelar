import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../atoms/custom_text_field.dart';
import '../molecules/filter_dropdown.dart';
import '../organisms/add_task_form.dart';
import '../organisms/task_list_item.dart';
import '../organisms/todo_header.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import 'package:intl/intl.dart';

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

  void _deleteAll() {
    if (_tasks.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Hapus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus semua tugas dalam daftar ini? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _tasks.clear();
                      });
                      _saveTasks();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text(
                      'Hapus Semua',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _pickDate() async {
    // Tampilkan opsi mau jenis tanggal yang mana
    final int? choice = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Tipe Waktu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTypeOption(
                context: context,
                icon: Icons.notes_rounded,
                title: 'Catatan Biasa',
                subtitle: 'Tanpa alarm. Hanya pengingat visual.',
                onTap: () => Navigator.pop(ctx, 1),
              ),
              const SizedBox(height: 8),
              _buildTypeOption(
                context: context,
                icon: Icons.event_rounded,
                title: 'Acara Masa Depan',
                subtitle: '1 Tanggal. Ada alarm pengingat H-7.',
                onTap: () => Navigator.pop(ctx, 2),
              ),
              const SizedBox(height: 8),
              _buildTypeOption(
                context: context,
                icon: Icons.alarm_rounded,
                title: 'Kejar Target (Deadline)',
                subtitle: 'Pilih rentang. Peringatan berkali-kali!',
                onTap: () => Navigator.pop(ctx, 3),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return false;

    if (choice == 1) {
      // Single Date (Catatan Biasa)
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
      // Single Date (Acara Masa Depan)
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
      // Date Range (Deadline Berdarah)
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

  Widget _buildTypeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAddFlow() async {
    final title = _taskNameCtrl.text.trim();
    if (title.isEmpty) return;

    final picked = await _pickDate();
    if (!picked) return; // if user cancels or doesn't pick

    if (!mounted) return;

    final List<String> categories = [
      '🔴 Urgent',
      '🔵 Kuliah',
      '🟢 Pribadi',
      '⚪ Lain-lain',
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Detail Tambahan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📝 ${_taskNameCtrl.text}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (_selectedDateRange != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_singleDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_singleDate!),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Kategori:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                _selectedCategory = selected ? cat : null;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Catatan Ekstra / Sub-Task:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _descriptionCtrl,
                        hintText: 'Tulis detail tambahan (opsional)...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _addTask();
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
              onDelete: () => _deleteTask(t.id),
            ),
          )
          .toList(),
    );
  }
}
