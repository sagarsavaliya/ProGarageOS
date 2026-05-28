import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/vehicle_catalog_models.dart';

class CatalogSearchField extends StatelessWidget {
  final String hint;
  final String? initialValue;
  final bool enabled;
  final Future<List<CatalogOption>> Function(String query) onSearch;
  final ValueChanged<CatalogOption?> onSelected;
  final VoidCallback? onChanged;

  const CatalogSearchField({
    super.key,
    required this.hint,
    required this.onSearch,
    required this.onSelected,
    this.initialValue,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CatalogOption>(
      initialValue: TextEditingValue(text: initialValue ?? ''),
      displayStringForOption: (option) => option.name,
      optionsBuilder: (textEditingValue) async {
        if (!enabled) return const Iterable<CatalogOption>.empty();
        return onSearch(textEditingValue.text.trim());
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          style: AppTextStyles.bodyMedium,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {
            onChanged?.call();
            onSelected(null);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryOrange),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220,
                maxWidth: MediaQuery.sizeOf(context).width - 40,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option.name, style: AppTextStyles.bodyMedium),
                    subtitle: option.fuelType != null
                        ? Text(
                            [option.fuelType, option.transmission]
                                .whereType<String>()
                                .where((v) => v.isNotEmpty)
                                .join(' · '),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          )
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
