import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_text_field.dart';
import 'auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure = true;
  bool _gdprConsent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_gdprConsent) {
      context.showSnack('Απαιτείται αποδοχή όρων GDPR', isError: true);
      return;
    }
    await ref.read(authNotifierProvider.notifier).register(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    authState.whenData((s) {
      if (s.isAuthenticated) context.go(AppRoutes.onboarding);
    });
    authState.whenOrNull(
      error: (e, _) => context.showSnack(e.toString(), isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Δημιουργία λογαριασμού'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MbTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Απαιτείται email';
                    if (!v.isValidEmail) return 'Μη έγκυρο email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                MbTextField(
                  controller: _passwordCtrl,
                  label: 'Κωδικός',
                  hint: 'Τουλάχιστον 8 χαρακτήρες',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    color: AppColors.textMuted,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Απαιτείται κωδικός';
                    if (!v.isValidPassword) return 'Τουλάχιστον 8 χαρακτήρες';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                MbTextField(
                  controller: _confirmCtrl,
                  label: 'Επιβεβαίωση κωδικού',
                  hint: '••••••••',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Οι κωδικοί δεν ταιριάζουν';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // GDPR consent
                InkWell(
                  onTap: () => setState(() => _gdprConsent = !_gdprConsent),
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _gdprConsent,
                        onChanged: (v) =>
                            setState(() => _gdprConsent = v ?? false),
                        activeColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: const [
                              TextSpan(text: 'Αποδέχομαι την '),
                              TextSpan(
                                text: 'Πολιτική Απορρήτου',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' και τους '),
                              TextSpan(
                                text: 'Όρους Χρήσης',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' (GDPR)'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // AI disclaimer
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppSpacing.rSm),
                    border: Border.all(color: const Color(0xFFBEE3F8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Το MindBridge χρησιμοποιεί AI και δεν '
                          'αντικαθιστά επαγγελματία ψυχολόγο. '
                          'Γνωρίζεις ότι μιλάς με AI (EU AI Act Art. 52).',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                MbButton(
                  label: 'Δημιουργία λογαριασμού',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
