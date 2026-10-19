import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final label = isToday
        ? 'Hoje'
        : day == yesterday
        ? 'Ontem'
        : Fmt.dayMonth(day);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.control,
        border: Border.all(color: context.pic.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
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
