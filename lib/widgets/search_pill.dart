import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onEditingComplete,
    required this.onClear,
    this.hint = 'Buscar lugares',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;
  final VoidCallback onClear;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.searchHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        style: AppTypography.label(fontSize: 15, color: AppColors.textLight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body(
            fontSize: 15,
            color: AppColors.textLight.withValues(alpha: 0.85),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
