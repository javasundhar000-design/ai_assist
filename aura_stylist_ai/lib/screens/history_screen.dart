import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'outfit_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Resolve each entry's outfit via AppState (covers custom outfits too);
    // an entry whose outfit was since deleted is simply skipped.
    final resolved = appState.history
        .map((e) => (entry: e, outfit: appState.outfitById(e.outfitId)))
        .where((r) => r.outfit != null)
        .toList();
    final grouped = groupBy(resolved, (r) => r.entry.group);

    final body = resolved.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('No looks captured yet — try an outfit and hit capture to build your history.',
                  textAlign: TextAlign.center, style: AppTextStyles.body),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
            children: grouped.entries.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.key, style: AppTextStyles.caption.copyWith(color: AppColors.violet, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...group.value.mapIndexed((i, r) => _TimelineTile(
                          entry: r.entry,
                          outfit: r.outfit!,
                          isLast: i == group.value.length - 1,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => OutfitDetailsScreen(outfit: r.outfit!)),
                          ),
                        )),
                  ],
                ),
              );
            }).toList(),
          );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Text('History', style: AppTextStyles.h1),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('History', style: AppTextStyles.h1)),
      body: body,
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final HistoryEntry entry;
  final Outfit outfit;
  final bool isLast;
  final VoidCallback onTap;
  const _TimelineTile({required this.entry, required this.outfit, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
              ),
              if (!isLast) Expanded(child: Container(width: 1.4, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AuraCard(
                onTap: onTap,
                child: Row(
                  children: [
                    OutfitCoverImage(
                      imagePath: entry.capturedImagePath ?? outfit.coverImagePath,
                      accent: outfit.accent,
                      height: 56,
                      width: 56,
                      borderRadius: AppRadii.sm,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(outfit.name, style: AppTextStyles.bodyStrong),
                          const SizedBox(height: 3),
                          Text('${outfit.fashionScore}/100', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                    Text(entry.time, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
