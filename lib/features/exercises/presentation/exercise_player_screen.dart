import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

// ── Exercise types ─────────────────────────────────────────────────────────
enum ExerciseType { breathing478, boxBreathing, grounding54321, thoughtRecord, bodyScan, gratitude }

class ExerciseConfig {
  const ExerciseConfig({
    required this.type,
    required this.title,
    required this.emoji,
    required this.color,
    required this.badge,
  });
  final ExerciseType type;
  final String title, emoji, badge;
  final Color color;
}

// ── Screen ─────────────────────────────────────────────────────────────────
class ExercisePlayerScreen extends StatefulWidget {
  const ExercisePlayerScreen({super.key, required this.config});
  final ExerciseConfig config;

  @override
  State<ExercisePlayerScreen> createState() => _ExercisePlayerScreenState();
}

class _ExercisePlayerScreenState extends State<ExercisePlayerScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return switch (widget.config.type) {
      ExerciseType.breathing478    => _BreathingScreen(config: widget.config, phases: const [4, 7, 8], labels: const ['Εισπνοή', 'Κράτα', 'Εκπνοή']),
      ExerciseType.boxBreathing    => _BreathingScreen(config: widget.config, phases: const [4, 4, 4, 4], labels: const ['Εισπνοή', 'Κράτα', 'Εκπνοή', 'Κράτα']),
      ExerciseType.grounding54321  => _GroundingScreen(config: widget.config),
      ExerciseType.thoughtRecord   => _ThoughtRecordScreen(config: widget.config),
      ExerciseType.bodyScan        => _GuidedScreen(config: widget.config, steps: _bodyScanSteps),
      ExerciseType.gratitude       => _GratitudeScreen(config: widget.config),
    };
  }
}

// ── Breathing exercise ─────────────────────────────────────────────────────
class _BreathingScreen extends StatefulWidget {
  const _BreathingScreen({
    required this.config,
    required this.phases,
    required this.labels,
  });
  final ExerciseConfig config;
  final List<int> phases;
  final List<String> labels;

  @override
  State<_BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<_BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Timer? _timer;
  int _phaseIndex = 0;
  int _secondsLeft = 0;
  bool _running = false;
  int _cycleCount = 0;

  int get _currentPhase => widget.phases[_phaseIndex];
  String get _currentLabel => widget.labels[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _secondsLeft = widget.phases[0];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() { _running = true; _phaseIndex = 0; _secondsLeft = _currentPhase; });
    _animatePhase();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _ctrl.stop();
    setState(() { _running = false; _phaseIndex = 0; _secondsLeft = widget.phases[0]; _cycleCount = 0; });
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _phaseIndex = (_phaseIndex + 1) % widget.phases.length;
        if (_phaseIndex == 0) _cycleCount++;
        _secondsLeft = _currentPhase;
        _animatePhase();
      }
    });
  }

  void _animatePhase() {
    _ctrl.stop();
    final isExpand = _currentLabel == 'Εισπνοή';
    final isHold   = _currentLabel == 'Κράτα';
    final dur = Duration(seconds: _currentPhase);
    if (isHold) {
      // No animation for hold
    } else if (isExpand) {
      _ctrl.animateTo(1.0, duration: dur, curve: Curves.easeInOut);
    } else {
      _ctrl.animateTo(0.0, duration: dur, curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.config.color,
      appBar: AppBar(
        backgroundColor: widget.config.color,
        elevation: 0,
        title: Text(widget.config.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Spacer(),
          // Breathing circle
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final scale = _running
                  ? 0.6 + _ctrl.value * 0.4
                  : 0.6;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Container(
                    width: 260 * scale + 20,
                    height: 260 * scale + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withOpacity(0.08),
                    ),
                  ),
                  // Main circle
                  Container(
                    width: 260 * scale,
                    height: 260 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brand.withOpacity(0.4),
                          AppColors.brand.withOpacity(0.15),
                        ],
                      ),
                      border: Border.all(color: AppColors.brand, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _running ? _currentLabel : widget.config.emoji,
                          style: TextStyle(
                            fontSize: _running ? 20 : 48,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_running) ...[
                          const SizedBox(height: 6),
                          Text(
                            '$_secondsLeft',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: AppColors.brand,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Cycle counter
          if (_running && _cycleCount > 0)
            Text(
              'Κύκλοι: $_cycleCount',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          // Phase dots
          if (_running)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.phases.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _phaseIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _phaseIndex ? AppColors.brand : AppColors.gridline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          const Spacer(),
          // Button
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _running ? _stop : _start,
                icon: Icon(_running ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(
                  _running ? 'Σταμάτα' : 'Ξεκίνα',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _running
                      ? AppColors.statusCritical
                      : AppColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rFull),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5-4-3-2-1 Grounding ────────────────────────────────────────────────────
class _GroundingScreen extends StatefulWidget {
  const _GroundingScreen({required this.config});
  final ExerciseConfig config;

  @override
  State<_GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<_GroundingScreen> {
  int _stepIndex = 0;
  final List<List<String>> _answers = List.generate(5, (_) => []);
  final _ctrl = TextEditingController();

  static const _steps = [
    (count: 5, sense: '👁️', prompt: 'Τι βλέπεις τώρα;', hint: 'π.χ. ένα παράθυρο, ένα τραπέζι...'),
    (count: 4, sense: '✋', prompt: 'Τι αγγίζεις / νιώθεις;', hint: 'π.χ. την καρέκλα, τα ρούχα σου...'),
    (count: 3, sense: '👂', prompt: 'Τι ακούς;', hint: 'π.χ. τη σιωπή, μουσική, φωνές...'),
    (count: 2, sense: '👃', prompt: 'Τι μυρίζεις;', hint: 'π.χ. καφέ, φρέσκο αέρα...'),
    (count: 1, sense: '👅', prompt: 'Τι γεύση νιώθεις;', hint: 'π.χ. τσίχλα, καφέ, τίποτα...'),
  ];

  bool get _stepDone => _answers[_stepIndex].length >= _steps[_stepIndex].count;
  bool get _isDone => _stepIndex >= _steps.length;

  void _addAnswer() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_answers[_stepIndex].length >= _steps[_stepIndex].count) return;
    setState(() { _answers[_stepIndex].add(text); _ctrl.clear(); });
    if (_stepDone && _stepIndex < _steps.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _stepIndex++);
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isDone) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Άριστα!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Είσαι εδώ, στο παρόν.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Τέλος'),
              ),
            ],
          ),
        ),
      );
    }

    final step = _steps[_stepIndex];
    return Scaffold(
      backgroundColor: widget.config.color,
      appBar: AppBar(
        backgroundColor: widget.config.color,
        elevation: 0,
        title: Text(widget.config.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: List.generate(5, (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: i == _stepIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _stepIndex ? AppColors.brand : AppColors.gridline,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(step.sense, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Βρες ${step.count} πράγματα',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              step.prompt,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Answers so far
            for (int i = 0; i < step.count; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: i < _answers[_stepIndex].length
                      ? AppColors.brand.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                  border: Border.all(
                    color: i < _answers[_stepIndex].length
                        ? AppColors.brand
                        : AppColors.gridline,
                  ),
                ),
                child: Text(
                  i < _answers[_stepIndex].length
                      ? _answers[_stepIndex][i]
                      : '${i + 1}.',
                  style: TextStyle(
                    fontSize: 14,
                    color: i < _answers[_stepIndex].length
                        ? AppColors.brandDark
                        : AppColors.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (!_stepDone) ...[
              TextField(
                controller: _ctrl,
                autofocus: true,
                onSubmitted: (_) => _addAnswer(),
                decoration: InputDecoration(
                  hintText: step.hint,
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rSm),
                    borderSide: const BorderSide(color: AppColors.gridline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rSm),
                    borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.brand),
                    onPressed: _addAnswer,
                  ),
                ),
              ),
            ],
            if (_stepDone && _stepIndex == _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => setState(() => _stepIndex++),
                    child: const Text('Ολοκλήρωση ✓'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Thought Record (CBT) ───────────────────────────────────────────────────
class _ThoughtRecordScreen extends StatefulWidget {
  const _ThoughtRecordScreen({required this.config});
  final ExerciseConfig config;

  @override
  State<_ThoughtRecordScreen> createState() => _ThoughtRecordScreenState();
}

class _ThoughtRecordScreenState extends State<_ThoughtRecordScreen> {
  final _ctrls = List.generate(5, (_) => TextEditingController());
  int _step = 0;

  static const _prompts = [
    ('🎯', 'Κατάσταση', 'Τι συνέβη; Πότε; Πού;'),
    ('💭', 'Αυτόματη Σκέψη', 'Τι πέρασε από το μυαλό σου; Τι είπες στον εαυτό σου;'),
    ('😔', 'Συναίσθημα', 'Τι συναίσθημα ένιωσες; Πόσο έντονα (0-100%);'),
    ('🔍', 'Στοιχεία', 'Ποια στοιχεία υποστηρίζουν/αντικρούουν αυτή τη σκέψη;'),
    ('✨', 'Εναλλακτική Σκέψη', 'Πώς θα μπορούσες να δεις αυτό διαφορετικά;'),
  ];

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_step >= _prompts.length) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text('📝 Ημερολόγιο Σκέψεων', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.lg),
              for (int i = 0; i < _prompts.length; i++) ...[
                Text('${_prompts[i].$1} ${_prompts[i].$2}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(_ctrls[i].text.isEmpty ? '—' : _ctrls[i].text,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Αποθήκευση & Έξοδος'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (emoji, title, hint) = _prompts[_step];
    return Scaffold(
      backgroundColor: widget.config.color,
      appBar: AppBar(
        backgroundColor: widget.config.color,
        elevation: 0,
        title: Text(widget.config.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / _prompts.length,
              backgroundColor: AppColors.gridline,
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TextField(
                controller: _ctrls[_step],
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rSm)),
                  hintText: 'Γράψε εδώ...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => setState(() => _step++),
                style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
                child: Text(_step < _prompts.length - 1 ? 'Επόμενο →' : 'Δες Σύνοψη'),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Guided text exercise (body scan, etc.) ─────────────────────────────────
class _GuidedScreen extends StatefulWidget {
  const _GuidedScreen({required this.config, required this.steps});
  final ExerciseConfig config;
  final List<(String, String)> steps;

  @override
  State<_GuidedScreen> createState() => _GuidedScreenState();
}

class _GuidedScreenState extends State<_GuidedScreen> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    if (_i >= widget.steps.length) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.config.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Ωραία δουλειά!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Τέλος')),
          ]),
        ),
      );
    }
    final (title, body) = widget.steps[_i];
    return Scaffold(
      backgroundColor: widget.config.color,
      appBar: AppBar(
        backgroundColor: widget.config.color,
        elevation: 0,
        title: Text(widget.config.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_i + 1) / widget.steps.length,
              backgroundColor: AppColors.gridline,
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(4),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            Text(body, style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textSecondary)),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => setState(() => _i++),
                child: Text(_i < widget.steps.length - 1 ? 'Συνέχεια →' : 'Ολοκλήρωση ✓'),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Gratitude journal ──────────────────────────────────────────────────────
class _GratitudeScreen extends StatefulWidget {
  const _GratitudeScreen({required this.config});
  final ExerciseConfig config;

  @override
  State<_GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<_GratitudeScreen> {
  final _ctrls = List.generate(3, (_) => TextEditingController());
  bool _done = false;

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🙏', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Ευχαριστώ!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Η ευγνωμοσύνη ενισχύει τη θετική διάθεση.',
                style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Τέλος')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: widget.config.color,
      appBar: AppBar(
        backgroundColor: widget.config.color,
        elevation: 0,
        title: Text(widget.config.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📓', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('3 Πράγματα Ευγνωμοσύνης', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Τι σε έκανε να νιώσεις ευγνώμων σήμερα;',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            for (int i = 0; i < 3; i++) ...[
              Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _ctrls[i],
                decoration: InputDecoration(
                  hintText: 'π.χ. ${["Η υγεία μου", "Ένας φίλος", "Ο καφές μου"][i]}...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rSm)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rSm),
                    borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _ctrls.every((c) => c.text.trim().isNotEmpty)
                    ? () => setState(() => _done = true)
                    : null,
                child: const Text('Αποθήκευση'),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Body scan steps ────────────────────────────────────────────────────────
const _bodyScanSteps = [
  ('Ξεκινάμε', 'Βρες μια άνετη θέση — κάθισε ή ξάπλωσε. Κλείσε τα μάτια αν θέλεις. Πάρε 3 βαθιές αναπνοές.'),
  ('Πόδια', 'Φέρε την προσοχή σου στα πόδια σου. Νιώσε τη σύνδεση με το πάτωμα. Χαλάρωσε κάθε δάχτυλο.'),
  ('Κνήμες & Γόνατα', 'Ανέβα στις κνήμες και τα γόνατα. Παρατήρησε αν υπάρχει τάση ή πόνος. Ανάπνεε.'),
  ('Ισχία & Κοιλιά', 'Φέρε την προσοχή σου στα ισχία και την κοιλιά. Άφησε την κοιλιά να χαλαρώσει με κάθε εκπνοή.'),
  ('Στήθος & Ώμοι', 'Νιώσε το στήθος σου να ανεβαίνει και να κατεβαίνει. Κατέβασε τους ώμους μακριά από τα αυτιά.'),
  ('Χέρια & Αντιβράχια', 'Παρατήρησε τα χέρια σου. Άφησε κάθε δάχτυλο να χαλαρώσει. Νιώσε τον αέρα στο δέρμα.'),
  ('Λαιμός & Πρόσωπο', 'Χαλάρωσε τον λαιμό, τη γνάθο, τα μάτια, το μέτωπο. Άφησε κάθε μυ να ξεκουραστεί.'),
  ('Ολόκληρο το σώμα', 'Φέρε την προσοχή σου σε ολόκληρο το σώμα. Νιώσε το αίσθημα ηρεμίας που έχεις δημιουργήσει.'),
];
