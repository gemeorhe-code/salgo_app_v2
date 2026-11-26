import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
      style: AppTypography.label(fontSize: 15, color: AppColors.textLight),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textLight),
      hint: Text(
        hint,
        style: AppTypography.body(
          fontSize: 15,
          color: AppColors.textLight.withValues(alpha: 0.85),
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
