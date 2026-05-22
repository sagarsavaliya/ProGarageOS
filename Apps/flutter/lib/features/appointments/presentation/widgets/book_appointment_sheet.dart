import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../customers/data/customers_repository.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../../jobs/data/garage_resources_repository.dart';
import '../../../jobs/presentation/providers/create_job_provider.dart' show ServiceCategoryOption;
import '../../data/appointments_repository.dart';
import '../providers/appointments_provider.dart';

Future<void> showBookAppointmentSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BookAppointmentSheet(ref: ref),
    ),
  );
}

class _BookAppointmentSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _BookAppointmentSheet({required this.ref});

  @override
  ConsumerState<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends ConsumerState<_BookAppointmentSheet> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _startTimeController = TextEditingController(text: '10:00');
  final _endTimeController = TextEditingController(text: '12:00');

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<CustomerVehicleSummary> _vehicles = [];
  CustomerVehicleSummary? _selectedVehicle;
  String? _categoryUuid;
  List<ServiceCategoryOption> _categories = [];
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(garageResourcesRepositoryProvider).fetchServiceCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _searchCustomers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _customers = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final result =
          await ref.read(customersRepositoryProvider).fetchCustomers(search: query, perPage: 8);
      setState(() {
        _customers = result.customers;
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  Future<void> _selectCustomer(Customer customer) async {
    setState(() {
      _selectedCustomer = customer;
      _selectedVehicle = null;
      _vehicles = [];
      _customers = [];
      _searchController.text = customer.fullName;
    });
    try {
      final detail = await ref.read(customersRepositoryProvider).fetchCustomer(customer.uuid);
      setState(() => _vehicles = detail.vehicles);
      if (_vehicles.length == 1) _selectedVehicle = _vehicles.first;
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null || _selectedVehicle == null) {
      setState(() => _error = 'Select a customer and vehicle.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appointmentsRepositoryProvider).bookAppointment(
            customerUuid: _selectedCustomer!.uuid,
            vehicleUuid: _selectedVehicle!.uuid,
            scheduledDate: DateFormat('yyyy-MM-dd').format(_date),
            startTime: _startTimeController.text.trim(),
            endTime: _endTimeController.text.trim(),
            serviceCategoryUuid: _categoryUuid,
            notes: _notesController.text.trim(),
          );
      ref.read(appointmentsProvider.notifier).refresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = failureMessage(e);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Book appointment', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Find customer',
                hintText: 'Name or phone',
              ),
              onChanged: _searchCustomers,
            ),
            if (_searching) const LinearProgressIndicator(color: AppColors.primaryOrange),
            if (_customers.isNotEmpty)
              ..._customers.map(
                (c) => ListTile(
                  dense: true,
                  title: Text(c.fullName),
                  subtitle: Text(c.phonePrimary),
                  onTap: () => _selectCustomer(c),
                ),
              ),
            if (_vehicles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Vehicle', style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicle?.uuid,
                decoration: const InputDecoration(labelText: 'Select vehicle'),
                items: _vehicles
                    .map((v) => DropdownMenuItem(
                          value: v.uuid,
                          child: Text(v.registrationNumber),
                        ))
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedVehicle = _vehicles.firstWhere((v) => v.uuid == id);
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change date')),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(labelText: 'End (HH:mm)'),
                  ),
                ),
              ],
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _categoryUuid,
                decoration: const InputDecoration(labelText: 'Service (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('General')),
                  ..._categories.map(
                    (c) => DropdownMenuItem(value: c.uuid, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryUuid = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppColors.statusRed)),
            ],
            const SizedBox(height: 16),
            AppButton(label: _loading ? 'Booking…' : 'Book', onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}
