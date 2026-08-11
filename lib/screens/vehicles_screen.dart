import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vehicleProvider.notifier).fetchVehicles());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        backgroundColor: AppColors.electricBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: state.loading && state.vehicles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No vehicles registered yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to add your first vehicle',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.vehicles.length,
                  itemBuilder: (context, index) {
                    final v = state.vehicles[index];
                    return _VehicleCard(
                      vehicle: v,
                      isDark: isDark,
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Vehicle'),
                            content: Text(
                                'Remove ${v['make']} ${v['model']} (${v['plate_number']})?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.error),
                                  child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref
                              .read(vehicleProvider.notifier)
                              .deleteVehicle(v['id'] as int);
                        }
                      },
                    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
                  },
                ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final makeC = TextEditingController();
    final modelC = TextEditingController();
    final yearC = TextEditingController();
    final colorC = TextEditingController();
    final plateC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add New Vehicle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: makeC,
                  decoration: const InputDecoration(
                    labelText: 'Make',
                    hintText: 'e.g. Toyota',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelC,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'e.g. Camry',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: yearC,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          hintText: 'e.g. 2022',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: colorC,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          hintText: 'e.g. White',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plateC,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    hintText: 'e.g. ABC-123-XY',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(vehicleProvider.notifier).addVehicle(
                            make: makeC.text.trim(),
                            model: modelC.text.trim(),
                            year: int.parse(yearC.text.trim()),
                            color: colorC.text.trim(),
                            plateNumber: plateC.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        String errorMsg = 'Failed to add vehicle';
                        if (e is DioException && e.response?.data != null) {
                          final data = e.response!.data;
                          if (data is Map) {
                            errorMsg = data['error'] ?? data['message'] ?? data['detail'] ?? errorMsg;
                          }
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save Vehicle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isDark;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = vehicle['ride_category'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.directions_car, color: Colors.white, size: 24),
        ),
        title: Text(
          '${vehicle['make']} ${vehicle['model']}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.pin_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(vehicle['plate_number'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(width: 12),
                Icon(Icons.palette_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${vehicle['color']} · ${vehicle['year']}',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            if (category != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category['name'] ?? 'Standard',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.error.withOpacity(0.7)),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
