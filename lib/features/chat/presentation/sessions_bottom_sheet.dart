import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../data/sessions_notifier.dart';
import '../domain/chat_session.dart';

class SessionsBottomSheet extends ConsumerWidget {
  const SessionsBottomSheet({
    super.key,
    required this.onSessionSelected,
    required this.onNewSession,
  });

  final void Function(String sessionId) onSessionSelected;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsNotifierProvider);
    final currentId     = sessionsAsync.valueOrNull?.currentId;
    final sessions      = sessionsAsync.valueOrNull?.sessions ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gridline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.brand, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Συνεδρίες',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // New session button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onNewSession();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Νέα', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.gridline),

          // Sessions list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: sessions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Δεν υπάρχουν συνεδρίες ακόμα',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.gridline),
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      final isActive = s.id == currentId;
                      return _SessionTile(
                        session:  s,
                        isActive: isActive,
                        onTap: () {
                          Navigator.pop(context);
                          onSessionSelected(s.id);
                        },
                        onDelete: () {
                          ref
                              .read(sessionsNotifierProvider.notifier)
                              .deleteSession(s.id);
                        },
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
        ],
      ),
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  void _shareSession() {
    final buf = StringBuffer();
    buf.writeln('📋 ${session.title}');
    buf.writeln('─────────────────────────');
    for (final m in session.messages) {
      final label = m.role == 'user' ? '👤 Εγώ' : '🤖 MindBridge AI';
      final time  = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
      buf.writeln('\n$label  [$time]');
      buf.writeln(m.content);
    }
    buf.writeln('\n─────────────────────────');
    buf.writeln('Εξαγωγή από MindBridge AI');
    Share.share(buf.toString(), subject: session.title);
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Χθες';
    if (diff.inDays < 7) return 'Πριν ${diff.inDays} μέρες';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          color: isActive
              ? AppColors.brand.withOpacity(0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Active indicator dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brand : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.brand
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (session.preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Date
              Text(
                _formatDate(session.updatedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),

              // Share button
              IconButton(
                icon: const Icon(Icons.ios_share_outlined, size: 16),
                color: AppColors.textMuted,
                onPressed: _shareSession,
                tooltip: 'Εξαγωγή',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.textMuted,
                onPressed: () => _confirmDelete(context),
                tooltip: 'Διαγραφή',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Διαγραφή συνεδρίας;'),
        content: Text('Θα διαγραφεί η συνεδρία "${session.title}". Δεν μπορεί να αναιρεθεί.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusCritical),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Διαγραφή'),
          ),
        ],
      ),
    );
  }
}
