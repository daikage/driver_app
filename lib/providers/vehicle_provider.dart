import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class VehicleState {
  final List<Map<String, dynamic>> vehicles;
  final bool loading;
  final String? error;

  const VehicleState({
    this.vehicles = const [],
    this.loading = false,
    this.error,
  });

  VehicleState copyWith({
    List<Map<String, dynamic>>? vehicles,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  VehicleNotifier() : super(const VehicleState());

  Future<void> fetchVehicles() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await ApiService.instance.dio.get('/vehicles');
      final list = (response.data['vehicles'] as List)
          .map((v) => (v as Map).cast<String, dynamic>())
          .toList();
      state = state.copyWith(vehicles: list, loading: false);
    } on Exception catch (e) {
      state = state.copyWith(loading: false, error: ApiService.friendlyError(e));
    }
  }

  Future<void> addVehicle({
    required String make,
    required String model,
    required int year,
    required String color,
    required String plateNumber,
    int? rideCategoryId,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await ApiService.instance.dio.post('/vehicles', data: {
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'plate_number': plateNumber,
        if (rideCategoryId != null) 'ride_category_id': rideCategoryId,
      });
      final vehicle = (response.data['vehicle'] as Map).cast<String, dynamic>();
      state = state.copyWith(
        vehicles: [...state.vehicles, vehicle],
        loading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(loading: false, error: ApiService.friendlyError(e));
      rethrow;
    }
  }

  Future<void> updateVehicle(int vehicleId, Map<String, dynamic> data) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await ApiService.instance.dio.put('/vehicles/$vehicleId', data: data);
      final updated = (response.data['vehicle'] as Map).cast<String, dynamic>();
      final updatedList = state.vehicles.map((v) {
        return v['id'] == vehicleId ? updated : v;
      }).toList();
      state = state.copyWith(vehicles: updatedList, loading: false);
    } on Exception catch (e) {
      state = state.copyWith(loading: false, error: ApiService.friendlyError(e));
      rethrow;
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ApiService.instance.dio.delete('/vehicles/$vehicleId');
      final filtered = state.vehicles.where((v) => v['id'] != vehicleId).toList();
      state = state.copyWith(vehicles: filtered, loading: false);
    } on Exception catch (e) {
      state = state.copyWith(loading: false, error: ApiService.friendlyError(e));
      rethrow;
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) => VehicleNotifier());
