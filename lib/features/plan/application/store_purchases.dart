import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/error/app_failure.dart';
import '../data/plan_repository.dart';

/// Situação de uma compra para a tela de planos.
sealed class StoreEvent {
  const StoreEvent();
}

class StorePending extends StoreEvent {
  const StorePending();
}

class StoreSucceeded extends StoreEvent {
  const StoreSucceeded();
}

class StoreFailed extends StoreEvent {
  const StoreFailed(this.message);
  final String message;
}

/// Assinaturas pelas lojas (Google Play Billing e StoreKit 2).
///
/// O app nunca libera o plano sozinho: envia o comprovante ao servidor, que
/// confere com a loja. A transação só é concluída depois da resposta
/// definitiva do servidor; falhas de rede deixam a compra pendente para nova
/// tentativa (a loja reenvia na próxima abertura).
class StorePurchases {
  StorePurchases(this._ref);

  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _events = StreamController<StoreEvent>.broadcast();

  Stream<StoreEvent> get events => _events.stream;

  static const _definitive = {'store_purchase_in_use', 'store_purchase_invalid', 'store_product_unknown', 'plan_already_active'};

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get platform => Platform.isIOS ? 'ios' : 'android';

  /// Começa a ouvir as compras (inclusive as pendentes de outra sessão).
  void listen() {
    if (!supported || _subscription != null) return;
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => unawaited(_handle(purchases)),
      onError: (Object e) => _events.add(StoreFailed('$e')),
    );
  }

  Future<List<ProductDetails>> products(List<String> ids) async {
    if (!supported || ids.isEmpty || !await InAppPurchase.instance.isAvailable()) return const [];
    final response = await InAppPurchase.instance.queryProductDetails(ids.toSet());
    final list = [...response.productDetails]..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return list;
  }

  Future<void> buy(ProductDetails product) async {
    listen();
    final accountToken = await _ref.read(planRepositoryProvider).accountToken();
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product, applicationUserName: accountToken),
    );
  }

  Future<void> restore() async {
    listen();
    final accountToken = await _ref.read(planRepositoryProvider).accountToken();
    await InAppPurchase.instance.restorePurchases(applicationUserName: accountToken);
  }

  Future<void> _handle(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      var complete = purchase.status != PurchaseStatus.pending;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(const StorePending());
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.error:
          _events.add(StoreFailed(purchase.error?.message ?? 'A loja não concluiu a compra.'));
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          try {
            await _ref
                .read(planRepositoryProvider)
                .submitPurchase(platform: platform, verificationData: purchase.verificationData.serverVerificationData);
            _ref.invalidate(currentPlanProvider);
            _events.add(const StoreSucceeded());
          } on AppFailure catch (e) {
            // Só conclui a transação recusada em definitivo no iOS (a cobrança já
            // ocorreu e a Apple reenviaria para sempre). No Android, sem
            // confirmação a Google Play estorna a compra em até 3 dias.
            complete = Platform.isIOS && _definitive.contains(e.code);
            _events.add(StoreFailed(e.message));
          }
      }
      if (complete && purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
        } on Object catch (e) {
          debugPrint('completePurchase: $e');
        }
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _events.close();
  }
}

final storePurchasesProvider = Provider<StorePurchases>((ref) {
  final store = StorePurchases(ref);
  ref.onDispose(() => unawaited(store.dispose()));
  return store;
});

/// Produtos de assinatura da loja deste aparelho, quando habilitada no servidor.
final storeProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final plan = await ref.watch(currentPlanProvider.future);
  final enabled = StorePurchases.supported && (Platform.isIOS ? plan.store.ios : plan.store.android);
  if (!enabled) return const [];
  return ref.watch(storePurchasesProvider).products(plan.store.productIds);
});
