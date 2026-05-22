import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/create_inventory_provider.dart';
import '../providers/inventory_provider.dart';

class AddPartScreen extends ConsumerStatefulWidget {
  const AddPartScreen({super.key});

  @override
  ConsumerState<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends ConsumerState<AddPartScreen> {
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _costController = TextEditingController();
  final _sellController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  String _unit = 'piece';

  static const _units = ['piece', 'litre', 'set', 'box', 'kg'];

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_skuController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SKU and name are required')),
      );
      return;
    }
    final item = await ref.read(createInventoryProvider.notifier).submit(
          sku: _skuController.text,
          name: _nameController.text,
          brand: _brandController.text,
          unit: _unit,
          costPrice: double.tryParse(_costController.text) ?? 0,
          sellingPrice: double.tryParse(_sellController.text) ?? 0,
          stockOnHand: int.tryParse(_stockController.text) ?? 0,
          lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        );
    if (item != null && mounted) {
      ref.read(inventoryProvider.notifier).refresh();
      context.pop();
      context.push('/inventory/${item.uuid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createInventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        title: Text('Add Part', style: AppTextStyles.titleMedium),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            controller: _skuController,
            label: 'SKU',
            hint: 'OIL-5W30-1L',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _nameController,
            label: 'Part name',
            hint: 'Engine oil 5W-30',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _brandController,
            label: 'Brand (optional)',
          ),
          const SizedBox(height: 12),
          Text('Unit', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _units.map((u) {
              final selected = _unit == u;
              return ChoiceChip(
                label: Text(u),
                selected: selected,
                onSelected: (_) => setState(() => _unit = u),
                selectedColor: AppColors.primaryOrangeDim,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _costController,
                  label: 'Cost (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _sellController,
                  label: 'Sell (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _stockController,
                  label: 'Stock on hand',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _thresholdController,
                  label: 'Low stock alert',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(state.errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed)),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: state.isSubmitting ? 'Saving…' : 'Save part',
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
