import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../utils/constants.dart';

class ReminderCard extends StatelessWidget {
  final String title;
  final String location;
  final String dueDate;
  final String status;
  final String timing;
  final IconData applianceIcon;

  const ReminderCard({
    super.key,
    required this.title,
    required this.location,
    required this.dueDate,
    required this.status,
    required this.timing,
    required this.applianceIcon,
  });

  bool get _isOverdue => status == 'Overdue';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _isOverdue ? AppColors.error : AppColors.secondaryTeal;
    final statusBackground = _isOverdue
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFCCFBF1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Icon(
                applianceIcon,
                color: AppColors.primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(location, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dueDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  timing,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
