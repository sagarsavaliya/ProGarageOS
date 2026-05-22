import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/customers_repository.dart';

Future<bool?> showUploadVehicleDocumentSheet({
  required BuildContext context,
  required CustomersRepository repository,
  required String vehicleUuid,
  required VoidCallback onUploaded,
  String? initialDocumentType,
  String? initialDocumentNumber,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UploadVehicleDocumentSheet(
      repository: repository,
      vehicleUuid: vehicleUuid,
      onUploaded: onUploaded,
      initialDocumentType: initialDocumentType,
      initialDocumentNumber: initialDocumentNumber,
    ),
  );
}

class _UploadVehicleDocumentSheet extends StatefulWidget {
  final CustomersRepository repository;
  final String vehicleUuid;
  final VoidCallback onUploaded;
  final String? initialDocumentType;
  final String? initialDocumentNumber;

  const _UploadVehicleDocumentSheet({
    required this.repository,
    required this.vehicleUuid,
    required this.onUploaded,
    this.initialDocumentType,
    this.initialDocumentNumber,
  });

  @override
  State<_UploadVehicleDocumentSheet> createState() => _UploadVehicleDocumentSheetState();
}

class _UploadVehicleDocumentSheetState extends State<_UploadVehicleDocumentSheet> {
  static const _types = {
    'rc': 'Registration (RC)',
    'insurance': 'Insurance',
    'puc': 'PUC',
    'fitness': 'Fitness',
    'permit': 'Permit',
    'other': 'Other',
  };

  String _documentType = 'insurance';
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  File? _file;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocumentType != null && _types.containsKey(widget.initialDocumentType)) {
      _documentType = widget.initialDocumentType!;
    }
    if (widget.initialDocumentNumber != null) {
      _numberController.text = widget.initialDocumentNumber!;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Future<void> _pickGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _file = File(result.files.single.path!));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 15)),
    );
    if (picked != null) {
      _expiryController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_file == null) {
      setState(() => _error = 'Choose a photo or PDF to upload.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.repository.uploadVehicleDocument(
        vehicleUuid: widget.vehicleUuid,
        documentType: _documentType,
        file: _file!,
        documentNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
        expiryDate: _expiryController.text.trim().isEmpty ? null : _expiryController.text.trim(),
      );
      if (mounted) {
        widget.onUploaded();
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Upload failed. Check file size (max 10 MB) and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload document', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _types.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _documentType = v ?? 'insurance'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _numberController,
            decoration: InputDecoration(
              hintText: 'Document number (optional)',
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _expiryController,
            readOnly: true,
            onTap: _pickExpiry,
            decoration: InputDecoration(
              hintText: 'Expiry date (optional)',
              suffixIcon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickCamera,
                  icon: const Icon(PhosphorIconsRegular.camera, size: 18),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickGallery,
                  icon: const Icon(PhosphorIconsRegular.file, size: 18),
                  label: const Text('File'),
                ),
              ),
            ],
          ),
          if (_file != null) ...[
            const SizedBox(height: 8),
            Text(
              _file!.path.split(RegExp(r'[/\\]')).last,
              style: AppTextStyles.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed)),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: 'Upload',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
