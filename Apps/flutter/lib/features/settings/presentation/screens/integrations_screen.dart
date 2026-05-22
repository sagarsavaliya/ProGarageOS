import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/integrations_repository.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  final _tokenController = TextEditingController();
  final _phoneIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  final _templateController = TextEditingController(text: 'pro_garage_otp');

  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _usePlatform = true;
  bool _enabled = false;
  bool _platformConfigured = false;
  String? _tokenPreview;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _phoneIdController.dispose();
    _businessIdController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(integrationsRepositoryProvider).fetchWhatsApp();
      setState(() {
        _usePlatform = data.usePlatformDefault;
        _enabled = data.enabled;
        _platformConfigured = data.platformConfigured;
        _tokenPreview = data.tokenPreview;
        _templateController.text = data.otpTemplate;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = failureMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(integrationsRepositoryProvider).updateWhatsApp({
        'use_platform_default': _usePlatform,
        'enabled': !_usePlatform && _enabled,
        if (_tokenController.text.isNotEmpty) 'token': _tokenController.text.trim(),
        if (_phoneIdController.text.isNotEmpty) 'phone_number_id': _phoneIdController.text.trim(),
        if (_businessIdController.text.isNotEmpty) 'business_account_id': _businessIdController.text.trim(),
        'otp_template': _templateController.text.trim(),
      });
      _tokenController.clear();
      setState(() {
        _success = 'Integration saved. Changes apply immediately — no app rebuild needed.';
        _saving = false;
      });
      await _load();
    } catch (e) {
      setState(() {
        _error = failureMessage(e);
        _saving = false;
      });
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _error = null;
      _success = null;
    });
    try {
      final message = await ref.read(integrationsRepositoryProvider).testWhatsApp();
      setState(() {
        _success = message;
        _testing = false;
      });
    } catch (e) {
      setState(() {
        _error = failureMessage(e);
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isOwnerProvider);

    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Integrations')),
        body: const Center(child: Text('Only the garage owner can manage integrations.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
        ),
        title: Text('Integrations', style: AppTextStyles.titleMedium),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'WhatsApp Business',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Used for staff PIN verification, customer OTP, job updates, and invoices.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ApiErrorView(message: _error!, onRetry: _load),
                  const SizedBox(height: 12),
                ],
                if (_success != null) ...[
                  Text(_success!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusGreen)),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use platform default (Akshara)'),
                  subtitle: Text(_platformConfigured ? 'Platform WhatsApp is configured' : 'Platform WhatsApp not configured'),
                  value: _usePlatform,
                  onChanged: (v) => setState(() => _usePlatform = v),
                ),
                if (!_usePlatform) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable garage WhatsApp'),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  if (_tokenPreview != null)
                    Text('Current token: $_tokenPreview', style: AppTextStyles.bodySmall),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'New access token (leave blank to keep)'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _phoneIdController,
                    decoration: const InputDecoration(labelText: 'Phone number ID'),
                  ),
                  TextField(
                    controller: _businessIdController,
                    decoration: const InputDecoration(labelText: 'Business account ID'),
                  ),
                ],
                TextField(
                  controller: _templateController,
                  decoration: const InputDecoration(labelText: 'OTP template name'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: _testing ? const Text('Testing…') : const Text('Test connection'),
                ),
              ],
            ),
    );
  }
}
