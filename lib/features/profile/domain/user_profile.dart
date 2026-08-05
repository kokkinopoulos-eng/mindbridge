import 'dart:convert';

class UserProfile {
  const UserProfile({
    this.name            = '',
    this.age             = 0,
    this.gender          = '',
    this.weightKg        = 0.0,
    this.heightCm        = 0.0,
    this.occupation      = '',
    this.maritalStatus   = '',
    this.hasChildren     = false,
    this.childrenCount   = 0,
    this.medication      = '',
    this.mentalHistory   = '',
    this.mainConcerns    = const [],
    this.therapyGoals    = '',
    this.sleepQuality    = '',
    this.exerciseLevel   = '',
    this.isCompleted     = false,
    this.aiKeypoints     = const [],   // AI-generated psychological insights
    this.aiKeypointDates = const [],   // corresponding timestamps (ISO strings)
  });

  final String name;
  final int    age;
  final String gender;
  final double weightKg;
  final double heightCm;
  final String occupation;
  final String maritalStatus;
  final bool   hasChildren;
  final int    childrenCount;
  final String medication;       // τρέχουσα φαρμακευτική αγωγή
  final String mentalHistory;    // ιστορικό ψυχικής υγείας
  final List<String> mainConcerns; // κύριες ανησυχίες
  final String therapyGoals;    // στόχοι θεραπείας
  final String sleepQuality;    // ποιότητα ύπνου
  final String exerciseLevel;   // επίπεδο άσκησης
  final bool   isCompleted;
  final List<String> aiKeypoints;      // AI psychological observations
  final List<String> aiKeypointDates;  // ISO date strings

  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  String get bmiCategory {
    final b = bmi;
    if (b <= 0)   return '';
    if (b < 18.5) return 'Λιποβαρής';
    if (b < 25)   return 'Φυσιολογικό';
    if (b < 30)   return 'Υπέρβαρος';
    return 'Παχυσαρκία';
  }

  UserProfile copyWith({
    String? name,
    int?    age,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? occupation,
    String? maritalStatus,
    bool?   hasChildren,
    int?    childrenCount,
    String? medication,
    String? mentalHistory,
    List<String>? mainConcerns,
    String? therapyGoals,
    String? sleepQuality,
    String? exerciseLevel,
    bool?   isCompleted,
    List<String>? aiKeypoints,
    List<String>? aiKeypointDates,
  }) => UserProfile(
    name:            name            ?? this.name,
    age:             age             ?? this.age,
    gender:          gender          ?? this.gender,
    weightKg:        weightKg        ?? this.weightKg,
    heightCm:        heightCm        ?? this.heightCm,
    occupation:      occupation      ?? this.occupation,
    maritalStatus:   maritalStatus   ?? this.maritalStatus,
    hasChildren:     hasChildren     ?? this.hasChildren,
    childrenCount:   childrenCount   ?? this.childrenCount,
    medication:      medication      ?? this.medication,
    mentalHistory:   mentalHistory   ?? this.mentalHistory,
    mainConcerns:    mainConcerns    ?? this.mainConcerns,
    therapyGoals:    therapyGoals    ?? this.therapyGoals,
    sleepQuality:    sleepQuality    ?? this.sleepQuality,
    exerciseLevel:   exerciseLevel   ?? this.exerciseLevel,
    isCompleted:     isCompleted     ?? this.isCompleted,
    aiKeypoints:     aiKeypoints     ?? this.aiKeypoints,
    aiKeypointDates: aiKeypointDates ?? this.aiKeypointDates,
  );

  /// Add a new keypoint (max 30 kept, oldest removed)
  UserProfile withNewKeypoint(String keypoint) {
    final kp    = List<String>.from(aiKeypoints)..add(keypoint);
    final dates = List<String>.from(aiKeypointDates)
      ..add(DateTime.now().toIso8601String());
    if (kp.length > 30) {
      kp.removeAt(0);
      dates.removeAt(0);
    }
    return copyWith(aiKeypoints: kp, aiKeypointDates: dates);
  }

  Map<String, dynamic> toJson() => {
    'name':            name,
    'age':             age,
    'gender':          gender,
    'weightKg':        weightKg,
    'heightCm':        heightCm,
    'occupation':      occupation,
    'maritalStatus':   maritalStatus,
    'hasChildren':     hasChildren,
    'childrenCount':   childrenCount,
    'medication':      medication,
    'mentalHistory':   mentalHistory,
    'mainConcerns':    mainConcerns,
    'therapyGoals':    therapyGoals,
    'sleepQuality':    sleepQuality,
    'exerciseLevel':   exerciseLevel,
    'isCompleted':     isCompleted,
    'aiKeypoints':     aiKeypoints,
    'aiKeypointDates': aiKeypointDates,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name:          j['name']          as String? ?? '',
    age:           j['age']           as int?    ?? 0,
    gender:        j['gender']        as String? ?? '',
    weightKg:      (j['weightKg']     as num?    ?? 0).toDouble(),
    heightCm:      (j['heightCm']     as num?    ?? 0).toDouble(),
    occupation:    j['occupation']    as String? ?? '',
    maritalStatus: j['maritalStatus'] as String? ?? '',
    hasChildren:   j['hasChildren']   as bool?   ?? false,
    childrenCount: j['childrenCount'] as int?    ?? 0,
    medication:    j['medication']    as String? ?? '',
    mentalHistory: j['mentalHistory'] as String? ?? '',
    mainConcerns:  (j['mainConcerns'] as List<dynamic>?)
                       ?.map((e) => e as String).toList() ?? [],
    therapyGoals:  j['therapyGoals']  as String? ?? '',
    sleepQuality:  j['sleepQuality']  as String? ?? '',
    exerciseLevel: j['exerciseLevel'] as String? ?? '',
    isCompleted:   j['isCompleted']   as bool?   ?? false,
    aiKeypoints:   (j['aiKeypoints'] as List<dynamic>?)
                       ?.map((e) => e as String).toList() ?? [],
    aiKeypointDates: (j['aiKeypointDates'] as List<dynamic>?)
                       ?.map((e) => e as String).toList() ?? [],
  );

  String encode() => jsonEncode(toJson());
  static UserProfile decode(String s) =>
      UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Summary for AI system prompt
  String toAiContext() {
    if (!isCompleted || name.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('=== ΠΡΟΦΙΛ ΧΡΗΣΤΗ ===');
    if (name.isNotEmpty)       buf.writeln('Όνομα: $name');
    if (age > 0)               buf.writeln('Ηλικία: $age ετών');
    if (gender.isNotEmpty)     buf.writeln('Φύλο: $gender');
    if (weightKg > 0)          buf.writeln('Βάρος: ${weightKg.toStringAsFixed(1)} kg');
    if (heightCm > 0)          buf.writeln('Ύψος: ${heightCm.toStringAsFixed(0)} cm');
    if (bmi > 0)               buf.writeln('ΔΜΣ: ${bmi.toStringAsFixed(1)} ($bmiCategory)');
    if (occupation.isNotEmpty) buf.writeln('Επάγγελμα: $occupation');
    if (maritalStatus.isNotEmpty) buf.writeln('Οικογενειακή κατάσταση: $maritalStatus');
    if (hasChildren)           buf.writeln('Παιδιά: $childrenCount');
    if (sleepQuality.isNotEmpty)  buf.writeln('Ποιότητα ύπνου: $sleepQuality');
    if (exerciseLevel.isNotEmpty) buf.writeln('Άσκηση: $exerciseLevel');
    if (mainConcerns.isNotEmpty)
      buf.writeln('Κύριες ανησυχίες: ${mainConcerns.join(', ')}');
    if (mentalHistory.isNotEmpty) buf.writeln('Ιστορικό ψυχικής υγείας: $mentalHistory');
    if (medication.isNotEmpty)    buf.writeln('Φαρμακευτική αγωγή: $medication');
    if (therapyGoals.isNotEmpty)  buf.writeln('Στόχοι θεραπείας: $therapyGoals');
    buf.writeln('=====================');

    // AI-accumulated psychological keypoints
    if (aiKeypoints.isNotEmpty) {
      buf.writeln('\n=== ΨΥΧΟΛΟΓΙΚΕΣ ΠΑΡΑΤΗΡΗΣΕΙΣ (από προηγούμενες συνεδρίες) ===');
      for (int i = 0; i < aiKeypoints.length; i++) {
        final date = i < aiKeypointDates.length
            ? _formatDate(aiKeypointDates[i])
            : '';
        buf.writeln('• ${aiKeypoints[i]}${date.isNotEmpty ? " ($date)" : ""}');
      }
      buf.writeln('Χρησιμοποίησε αυτές τις παρατηρήσεις για να κατανοείς καλύτερα τον χρήστη και να δείξεις συνέχεια στις συνεδρίες.');
      buf.writeln('==========================================================');
    }

    return buf.toString();
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
