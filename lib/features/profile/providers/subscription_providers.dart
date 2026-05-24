import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/session_providers.dart';

const joyfishMonthlyProductId = 'com.alvis.joyfish.vip.monthly';
const joyfishAnnualProductId = 'com.alvis.joyfish.vip.annual';
const joyfishSubscriptionProductIds = <String>{
  joyfishMonthlyProductId,
  joyfishAnnualProductId,
};

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
  return SubscriptionController(ref);
});

class SubscriptionState {
  const SubscriptionState({
    this.loading = false,
    this.purchasing = false,
    this.restoring = false,
    this.storeAvailable = false,
    this.products = const {},
    this.notFoundIds = const {},
    this.error,
    this.message,
  });

  final bool loading;
  final bool purchasing;
  final bool restoring;
  final bool storeAvailable;
  final Map<String, ProductDetails> products;
  final Set<String> notFoundIds;
  final String? error;
  final String? message;

  SubscriptionState copyWith({
    bool? loading,
    bool? purchasing,
    bool? restoring,
    bool? storeAvailable,
    Map<String, ProductDetails>? products,
    Set<String>? notFoundIds,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SubscriptionState(
      loading: loading ?? this.loading,
      purchasing: purchasing ?? this.purchasing,
      restoring: restoring ?? this.restoring,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      products: products ?? this.products,
      notFoundIds: notFoundIds ?? this.notFoundIds,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController(this.ref) : super(const SubscriptionState()) {
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        state = state.copyWith(
          purchasing: false,
          restoring: false,
          error: userFacingErrorMessage(error),
        );
      },
    );
    unawaited(loadProducts());
  }

  final Ref ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  Future<void> loadProducts() async {
    if (!Platform.isIOS) {
      state = state.copyWith(
        storeAvailable: false,
        loading: false,
        error: '当前仅支持 iOS App Store 订阅',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    final available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(
        loading: false,
        storeAvailable: false,
        error: '暂时无法连接 App Store，请稍后重试',
      );
      return;
    }

    final response =
        await _iap.queryProductDetails(joyfishSubscriptionProductIds);
    final products = {
      for (final product in response.productDetails) product.id: product,
    };
    state = state.copyWith(
      loading: false,
      storeAvailable: true,
      products: products,
      notFoundIds: response.notFoundIDs.toSet(),
      error: response.error?.message,
    );
  }

  Future<void> buy(String productId) async {
    final product = state.products[productId];
    if (product == null) {
      state = state.copyWith(error: '未找到订阅商品，请确认 App Store Connect 配置');
      return;
    }

    state = state.copyWith(
      purchasing: true,
      clearError: true,
      clearMessage: true,
    );
    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      state = state.copyWith(
        purchasing: false,
        error: '无法发起订阅，请稍后重试',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      restoring: true,
      clearError: true,
      clearMessage: true,
    );
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(purchasing: true);
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            purchasing: false,
            restoring: false,
            error: purchase.error?.message ?? '订阅失败，请稍后重试',
          );
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchasing: false,
            restoring: false,
            message: '已取消订阅',
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverPurchase(purchase);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .confirmAppleSubscription(
            productId: purchase.productID,
            purchaseId: purchase.purchaseID,
            transactionDate: purchase.transactionDate,
            source: purchase.verificationData.source,
            verificationData: purchase.verificationData.serverVerificationData,
            localVerificationData:
                purchase.verificationData.localVerificationData,
          );
      await ref.read(sessionControllerProvider.notifier).updateUser(user);
      state = state.copyWith(
        purchasing: false,
        restoring: false,
        message: '会员已开通，权益已同步',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        purchasing: false,
        restoring: false,
        error: userFacingErrorMessage(error),
      );
    }
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }
}
