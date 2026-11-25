import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomDropdown extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Seleccione',
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      onChanged: onChanged,
      dropdownColor: AppColors.orange,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      hint: Text(
        hint,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      items: [
        for (final String item in items)
          DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
