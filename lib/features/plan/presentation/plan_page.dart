import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/store_purchases.dart';
import '../data/plan_repository.dart';

/// Plano atual, uso de hoje, comparação e assinatura pelas lojas (quando habilitada).
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPlanProvider);
    final plans = ref.watch(plansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu plano')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(currentPlanProvider)
            ..invalidate(plansProvider);
          await ref.read(currentPlanProvider.future);
        },
        child: AsyncValueView<CurrentPlan>(
          value: current,
          onRetry: () => ref.invalidate(currentPlanProvider),
          data: (c) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano ${c.plan.name}',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (c.endsAt != null)
                        Text(
                          'Válido até ${Fmt.shortDate(c.endsAt!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                      Text('Uso de hoje', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final u in c.usage) ...[
                        Text(
                          u.limit == null
                              ? '${_capitalize(u.label)}: ${u.used} (ilimitado)'
                              : '${_capitalize(u.label)}: ${u.used} de ${u.limit}',
                        ),
                        if (u.limit != null && u.limit! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: LinearProgressIndicator(
                              value: (u.used / u.limit!).clamp(0, 1).toDouble(),
                            ),
                          ),
                      ],
                      Text(
                        'Os limites renovam à meia-noite.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Planos', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              AsyncValueView<List<PlanInfo>>(
                value: plans,
                onRetry: () => ref.invalidate(plansProvider),
                data: (list) => Column(
                  children: [
                    for (final p in list)
                      Card(
                        shape: p.code == c.plan.code
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  if (p.code == c.plan.code)
                                    const Chip(
                                      label: Text('Atual'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              if (p.description != null) Text(p.description!),
                              const SizedBox(height: 8),
                              for (final f in p.features)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(f)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _StoreSection(current: c),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Assinatura pela loja do aparelho. Some quando a loja não está habilitada.
class _StoreSection extends ConsumerStatefulWidget {
  const _StoreSection({required this.current});

  final CurrentPlan current;

  @override
  ConsumerState<_StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends ConsumerState<_StoreSection> {
  StreamSubscription<StoreEvent>? _events;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = ref.read(storePurchasesProvider)..listen();
    _events = store.events.listen((event) {
      if (!mounted) return;
      setState(() => _busy = event is StorePending);
      switch (event) {
        case StoreSucceeded():
          showMessage(context, 'Assinatura confirmada. Obrigado!');
        case StoreFailed(:final message):
          showMessage(context, message);
        case StorePending():
          showMessage(context, 'Compra pendente de confirmação pela loja.');
      }
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.current;
    final products = ref.watch(storeProductsProvider);
    final list = products.value ?? const <ProductDetails>[];

    if (!c.paymentsAvailable || (products.hasValue && list.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'A contratação de planos pelo app ainda não está disponível neste aparelho.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (products.isLoading) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }

    final store = ref.read(storePurchasesProvider);
    final fromStore = c.store.source == 'google_play' || c.store.source == 'app_store';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Assinar', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (fromStore)
          Text(
            c.store.autoRenew == false
                ? 'Sua assinatura não será renovada e termina na data acima.'
                : 'Sua assinatura é renovada automaticamente. Gerencie ou cancele na loja.',
            style: theme.textTheme.bodySmall,
          ),
        for (final p in list)
          Card(
            child: ListTile(
              title: Text(p.title),
              subtitle: Text(p.description),
              trailing: FilledButton(
                onPressed: _busy || fromStore ? null : () => _run(() => store.buy(p)),
                child: Text(p.price),
              ),
            ),
          ),
        TextButton(
          onPressed: _busy ? null : () => _run(store.restore),
          child: const Text('Restaurar compras'),
        ),
        Text(
          'O pagamento é feito pela ${Platform.isIOS ? 'App Store' : 'Google Play'}, com renovação automática até o cancelamento na própria loja. O plano é liberado após a confirmação da compra pelo nosso servidor.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
