import 'package:flutter/material.dart';

class FilterDropdown extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          value: currentValue,
          onChanged: onChanged,
          icon: const SizedBox.shrink(), // No icon for minimalism
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Semua Tugas')),
            DropdownMenuItem(value: 'pending', child: Text('Tertunda')),
            DropdownMenuItem(value: 'completed', child: Text('Selesai')),
          ],
        ),
      ),
    );
  }
}
