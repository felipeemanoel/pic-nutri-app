import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/design_system.dart';
import '../../core/utils/formatters.dart';
import '../state/selected_date.dart';

/// Navegação entre dias (anterior / hoje / próximo), sem permitir o futuro.
class DayNavigator extends ConsumerWidget {
  const DayNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final notifier = ref.read(selectedDateProvider.notifier);
    final isToday = day == SelectedDate.today();
    final yesterday = SelectedDate.today().subtract(const Duration(days: 1));
    final short = DateFormat('d MMM', 'pt_BR').format(day).replaceAll('.', '');
    final label = isToday
        ? 'Hoje, $short'
        : day == yesterday
        ? 'Ontem, $short'
        : Fmt.dayMonth(day);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.pic.border),
        boxShadow: Shadows.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Dia anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: notifier.previous,
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2020),
                lastDate: SelectedDate.today(),
              );
              if (picked != null) notifier.set(picked);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 22,
                  color: context.colors.primary,
                ),
                const SizedBox(width: Space.md),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Próximo dia',
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : notifier.next,
          ),
        ],
      ),
    );
  }
}
