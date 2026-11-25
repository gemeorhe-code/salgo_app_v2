import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SalgoLogo extends StatelessWidget {
  const SalgoLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: AppTheme.display(
              fontSize: size * 0.6,
              color: AppColors.textLight,
            ),
          ),
        ),
        SizedBox(width: size * 0.22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SALGO',
              style: AppTheme.display(
                fontSize: size * 0.42,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'APP',
              style: AppTheme.display(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w600,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
