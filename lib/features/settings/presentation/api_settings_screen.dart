import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/ai_provider_settings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final _openaiCtrl = TextEditingController();
  final _claudeCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();

  AiProvider _selectedProvider = AiProvider.openai;
  bool _loading = true;
  bool _saving  = false;

  // Which field is currently shown (obfuscated)
  final Map<AiProvider, bool> _obscured = {
    AiProvider.openai: true,
    AiProvider.claude: true,
    AiProvider.gemini: true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ref.read(aiSettingsNotifierProvider.future);
    if (!mounted) return;
    setState(() {
      _selectedProvider = settings.provider;
      _openaiCtrl.text  = settings.openaiKey;
      _claudeCtrl.text  = settings.claudeKey;
      _geminiCtrl.text  = settings.geminiKey;
      _loading          = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = AiSettings(
      provider:  _selectedProvider,
      openaiKey: _openaiCtrl.text.trim(),
      claudeKey: _claudeCtrl.text.trim(),
      geminiKey: _geminiCtrl.text.trim(),
    );
    await ref.read(aiSettingsNotifierProvider.notifier).save(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ρυθμίσεις αποθηκεύτηκαν ✓'),
        backgroundColor: AppColors.statusGood,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _openaiCtrl.dispose();
    _claudeCtrl.dispose();
    _geminiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ρυθμίσεις AI'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Info banner ───────────────────────────────────────────────
          _InfoBanner(),
          const SizedBox(height: AppSpacing.lg),

          // ── Provider selector ─────────────────────────────────────────
          const Text(
            'ΠΑΡΟΧΟΣ AI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProviderSelector(
            selected: _selectedProvider,
            onChanged: (p) => setState(() => _selectedProvider = p),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── API key fields ────────────────────────────────────────────
          const Text(
            'API KEYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _KeyField(
            label: 'OpenAI GPT-4o',
            hint: 'sk-...',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF10A37F),
            controller: _openaiCtrl,
            obscured: _obscured[AiProvider.openai]!,
            isActive: _selectedProvider == AiProvider.openai,
            onToggleObscure: () => setState(
              () => _obscured[AiProvider.openai] = !_obscured[AiProvider.openai]!,
            ),
            onTap: () => setState(() => _selectedProvider = AiProvider.openai),
            helpUrl: 'platform.openai.com/api-keys',
          ),
          const SizedBox(height: AppSpacing.sm),

          _KeyField(
            label: 'Anthropic Claude',
            hint: 'sk-ant-...',
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFFD97706),
            controller: _claudeCtrl,
            obscured: _obscured[AiProvider.claude]!,
            isActive: _selectedProvider == AiProvider.claude,
            onToggleObscure: () => setState(
              () => _obscured[AiProvider.claude] = !_obscured[AiProvider.claude]!,
            ),
            onTap: () => setState(() => _selectedProvider = AiProvider.claude),
            helpUrl: 'console.anthropic.com/settings/keys',
          ),
          const SizedBox(height: AppSpacing.sm),

          _KeyField(
            label: 'Google Gemini',
            hint: 'AIza...',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF4285F4),
            controller: _geminiCtrl,
            obscured: _obscured[AiProvider.gemini]!,
            isActive: _selectedProvider == AiProvider.gemini,
            onToggleObscure: () => setState(
              () => _obscured[AiProvider.gemini] = !_obscured[AiProvider.gemini]!,
            ),
            onTap: () => setState(() => _selectedProvider = AiProvider.gemini),
            helpUrl: 'aistudio.google.com/app/apikey',
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Save button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Αποθήκευση',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Privacy note ──────────────────────────────────────────────
          const Text(
            'Τα API keys αποθηκεύονται τοπικά στο κινητό σου με κρυπτογράφηση (Android Keystore). Δεν αποστέλλονται σε κανέναν server — οι αιτήσεις πηγαίνουν απευθείας στον πάροχο AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ── Info banner ────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          border: Border.all(color: AppColors.brand.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.brand, size: 18),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Χρειάζεσαι δικό σου API key για να χρησιμοποιήσεις το AI chat. Επίλεξε πάροχο, πρόσθεσε το key σου και ξεκίνα.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brand,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Provider selector chips ────────────────────────────────────────────────
class _ProviderSelector extends StatelessWidget {
  const _ProviderSelector({
    required this.selected,
    required this.onChanged,
  });

  final AiProvider selected;
  final ValueChanged<AiProvider> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: AiProvider.values.map((p) {
          final isSelected = selected == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(
                  right: p != AiProvider.gemini ? AppSpacing.sm : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      switch (p) {
                        AiProvider.openai => '⚡',
                        AiProvider.claude => '✨',
                        AiProvider.gemini => '⭐',
                      },
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      switch (p) {
                        AiProvider.openai => 'OpenAI',
                        AiProvider.claude => 'Claude',
                        AiProvider.gemini => 'Gemini',
                      },
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
}

// ── API key field ──────────────────────────────────────────────────────────
class _KeyField extends StatelessWidget {
  const _KeyField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.obscured,
    required this.isActive,
    required this.onToggleObscure,
    required this.onTap,
    required this.helpUrl,
  });

  final String label, hint, helpUrl;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final bool obscured, isActive;
  final VoidCallback onToggleObscure, onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            border: Border.all(
              color: isActive ? AppColors.brand : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.brand.withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(AppSpacing.rFull),
                      ),
                      child: const Text(
                        'Ενεργό',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    helpUrl,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                obscureText: obscured,
                onTap: onTap,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.brand),
                  ),
                  filled: true,
                  fillColor: AppColors.surface0,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscured ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
