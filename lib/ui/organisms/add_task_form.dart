import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../atoms/custom_text_field.dart';

class AddTaskForm extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAddDialog;

  const AddTaskForm({
    super.key,
    required this.controller,
    required this.onAddDialog,
  });

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CustomTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            hintText: 'Apa yang perlu dilakukan?',
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  _focusNode.unfocus();
                  widget.onAddDialog();
                }
              },
              tooltip: 'Atur & Tambah',
            ),
          ),
        ),
      ],
    );
  }
}
