import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class EarningState {
  final Map<String, dynamic>? wallet;
  final List<Map<String, dynamic>> earnings;
  final bool loading;
  final String? error;

  const EarningState({
    this.wallet,
    this.earnings = const [],
    this.loading = false,
    this.error,
  });

  EarningState copyWith({
    Map<String, dynamic>? wallet,
    List<Map<String, dynamic>>? earnings,
    bool? loading,
    String? error,
  }) {
    return EarningState(
      wallet: wallet ?? this.wallet,
      earnings: earnings ?? this.earnings,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class EarningNotifier extends StateNotifier<EarningState> {
  EarningNotifier() : super(const EarningState());

  Future<void> fetchWalletAndEarnings() async {
    state = state.copyWith(loading: true);
    try {
      final walletRes = await ApiService.instance.dio.get('/driver/wallet');
      final earningsRes = await ApiService.instance.dio.get('/driver/earnings');
      
      final wallet = (walletRes.data['wallet'] as Map).cast<String, dynamic>();
      final earningsList = (earningsRes.data['earnings'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
          
      state = state.copyWith(
        wallet: wallet,
        earnings: earningsList,
        loading: false,
        error: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        loading: false,
        error: ApiService.friendlyError(e),
      );
    }
  }
}

final earningProvider =
    StateNotifierProvider<EarningNotifier, EarningState>((ref) => EarningNotifier());
