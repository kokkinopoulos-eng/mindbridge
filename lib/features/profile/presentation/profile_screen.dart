import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_notifier.dart';
import '../domain/user_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl       = TextEditingController();
  final _ageCtrl        = TextEditingController();
  final _weightCtrl     = TextEditingController();
  final _heightCtrl     = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _historyCtrl    = TextEditingController();
  final _goalsCtrl      = TextEditingController();

  String _gender        = '';
  String _maritalStatus = '';
  bool   _hasChildren   = false;
  int    _childrenCount = 0;
  String _sleepQuality  = '';
  String _exerciseLevel = '';
  final List<String> _concerns = [];

  bool _loading = true;
  bool _saving  = false;

  static const _concerns_list = [
    'Άγχος', 'Κατάθλιψη', 'Στρες', 'Ύπνος', 'Σχέσεις',
    'Εργασία', 'Αυτοεκτίμηση', 'Τραύμα', 'Μοναξιά', 'Θυμός',
    'Πανικός', 'Φοβίες', 'Οικογένεια', 'Πένθος', 'Εθισμός',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(profileNotifierProvider.future);
    if (!mounted) return;
    setState(() {
      _nameCtrl.text       = profile.name;
      _ageCtrl.text        = profile.age > 0 ? profile.age.toString() : '';
      _weightCtrl.text     = profile.weightKg > 0
          ? profile.weightKg.toStringAsFixed(1) : '';
      _heightCtrl.text     = profile.heightCm > 0
          ? profile.heightCm.toStringAsFixed(0) : '';
      _occupationCtrl.text = profile.occupation;
      _medicationCtrl.text = profile.medication;
      _historyCtrl.text    = profile.mentalHistory;
      _goalsCtrl.text      = profile.therapyGoals;
      _gender              = profile.gender;
      _maritalStatus       = profile.maritalStatus;
      _hasChildren         = profile.hasChildren;
      _childrenCount       = profile.childrenCount;
      _sleepQuality        = profile.sleepQuality;
      _exerciseLevel       = profile.exerciseLevel;
      _concerns.addAll(profile.mainConcerns);
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = UserProfile(
      name:          _nameCtrl.text.trim(),
      age:           int.tryParse(_ageCtrl.text.trim()) ?? 0,
      gender:        _gender,
      weightKg:      double.tryParse(_weightCtrl.text.trim()) ?? 0,
      heightCm:      double.tryParse(_heightCtrl.text.trim()) ?? 0,
      occupation:    _occupationCtrl.text.trim(),
      maritalStatus: _maritalStatus,
      hasChildren:   _hasChildren,
      childrenCount: _childrenCount,
      medication:    _medicationCtrl.text.trim(),
      mentalHistory: _historyCtrl.text.trim(),
      mainConcerns:  List.from(_concerns),
      therapyGoals:  _goalsCtrl.text.trim(),
      sleepQuality:  _sleepQuality,
      exerciseLevel: _exerciseLevel,
      isCompleted:   _nameCtrl.text.trim().isNotEmpty,
    );
    await ref.read(profileNotifierProvider.notifier).save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Προφίλ αποθηκεύτηκε ✓'),
        backgroundColor: AppColors.statusGood,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _occupationCtrl.dispose();
    _medicationCtrl.dispose();
    _historyCtrl.dispose();
    _goalsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Το προφίλ μου'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand,
                    ),
                  )
                : const Text(
                    'Αποθήκευση',
                    style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Info banner ─────────────────────────────────────────────
          _infoBanner(),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 1: Βασικά στοιχεία ──────────────────────────────
          _sectionHeader('ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ', Icons.person_outline),
          const SizedBox(height: AppSpacing.sm),

          _textField(
            controller: _nameCtrl,
            label: 'Όνομα',
            hint: 'Πώς να σε λέω;',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _ageCtrl,
                  label: 'Ηλικία',
                  hint: 'π.χ. 28',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _chipSelector(
                  label: 'Φύλο',
                  options: ['Άντρας', 'Γυναίκα', 'Άλλο'],
                  selected: _gender,
                  onSelected: (v) => setState(() => _gender = v),
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _weightCtrl,
                  label: 'Βάρος (kg)',
                  hint: 'π.χ. 75',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _textField(
                  controller: _heightCtrl,
                  label: 'Ύψος (cm)',
                  hint: 'π.χ. 175',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          _textField(
            controller: _occupationCtrl,
            label: 'Επάγγελμα',
            hint: 'π.χ. Δάσκαλος, Μηχανικός, Άνεργος...',
            icon: Icons.work_outline,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 2: Οικογένεια ────────────────────────────────────
          _sectionHeader('ΟΙΚΟΓΕΝΕΙΑΚΗ ΚΑΤΑΣΤΑΣΗ', Icons.family_restroom),
          const SizedBox(height: AppSpacing.sm),

          _chipSelector(
            label: 'Κατάσταση',
            options: ['Ελεύθερος/η', 'Σε σχέση', 'Παντρεμένος/η',
                      'Διαζευγμένος/η', 'Χήρος/α'],
            selected: _maritalStatus,
            onSelected: (v) => setState(() => _maritalStatus = v),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Text('Παιδιά:', style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600,
              )),
              const SizedBox(width: 12),
              Switch(
                value: _hasChildren,
                onChanged: (v) => setState(() => _hasChildren = v),
                activeColor: AppColors.brand,
              ),
              if (_hasChildren) ...[
                const SizedBox(width: 8),
                const Text('Πόσα:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                _counterWidget(
                  value: _childrenCount,
                  onChanged: (v) => setState(() => _childrenCount = v),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 3: Καθημερινότητα ────────────────────────────────
          _sectionHeader('ΚΑΘΗΜΕΡΙΝΟΤΗΤΑ', Icons.wb_sunny_outlined),
          const SizedBox(height: AppSpacing.sm),

          _chipSelector(
            label: 'Ποιότητα ύπνου',
            options: ['Πολύ κακή', 'Κακή', 'Μέτρια', 'Καλή', 'Πολύ καλή'],
            selected: _sleepQuality,
            onSelected: (v) => setState(() => _sleepQuality = v),
          ),
          const SizedBox(height: AppSpacing.sm),

          _chipSelector(
            label: 'Επίπεδο άσκησης',
            options: ['Καθόλου', 'Σπάνια', '1-2 φορές/εβδ.',
                      '3-4 φορές/εβδ.', 'Καθημερινά'],
            selected: _exerciseLevel,
            onSelected: (v) => setState(() => _exerciseLevel = v),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 4: Ψυχική υγεία ──────────────────────────────────
          _sectionHeader('ΨΥΧΙΚΗ ΥΓΕΙΑ', Icons.psychology_outlined),
          const SizedBox(height: AppSpacing.sm),

          const Text(
            'Κύριες ανησυχίες (επίλεξε ό,τι σε αφορά)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _concerns_list.map((c) {
              final selected = _concerns.contains(c);
              return FilterChip(
                label: Text(c, style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) _concerns.add(c);
                  else _concerns.remove(c);
                }),
                selectedColor: AppColors.brand,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? AppColors.brand : AppColors.border,
                ),
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          _textField(
            controller: _historyCtrl,
            label: 'Ιστορικό ψυχικής υγείας',
            hint: 'π.χ. Διάγνωση κατάθλιψης 2020, θεραπεία για 1 χρόνο...',
            icon: Icons.history_edu_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),

          _textField(
            controller: _medicationCtrl,
            label: 'Τρέχουσα φαρμακευτική αγωγή',
            hint: 'π.χ. Sertraline 50mg, ή "Καμία"',
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 5: Στόχοι ────────────────────────────────────────
          _sectionHeader('ΣΤΟΧΟΙ ΘΕΡΑΠΕΙΑΣ', Icons.flag_outlined),
          const SizedBox(height: AppSpacing.sm),

          _textField(
            controller: _goalsCtrl,
            label: 'Τι θέλεις να πετύχεις;',
            hint: 'π.χ. Να μειώσω το άγχος μου, να βελτιώσω τις σχέσεις μου...',
            icon: Icons.stars_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Save button ──────────────────────────────────────────────
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
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Αποθήκευση προφίλ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _infoBanner() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          border: Border.all(color: AppColors.brand.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.psychology, color: AppColors.brand, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Αυτές οι πληροφορίες βοηθούν το AI να σε καταλαβαίνει καλύτερα και να σου δίνει εξατομικευμένες συμβουλές. Αποθηκεύονται μόνο τοπικά στη συσκευή σου.',
                style: TextStyle(
                  fontSize: 12, color: AppColors.brand, height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12,
          ),
        ),
      );

  Widget _chipSelector({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    bool compact = false,
  }) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((o) {
              final isSelected = selected == o;
              return ChoiceChip(
                label: Text(
                  o,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(o),
                selectedColor: AppColors.brand,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.brand : AppColors.border,
                ),
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 6,
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _counterWidget({
    required int value,
    required ValueChanged<int> onChanged,
  }) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed:
                value > 0 ? () => onChanged(value - 1) : null,
            color: AppColors.brand,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => onChanged(value + 1),
            color: AppColors.brand,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      );
}
