import 'package:flutter/material.dart';
import '../services/space_validation_service.dart';

/// Small floating chip showing the current issue count. Tapping opens
/// the full list. Hidden entirely when there are no issues.
class SpaceValidationBadge extends StatelessWidget {
  final List<SpaceValidationIssue> issues;
  const SpaceValidationBadge({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();

    final warningCount =
        issues.where((i) => i.severity == SpaceIssueSeverity.warning).length;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: warningCount > 0 ? scheme.errorContainer : scheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showIssuesSheet(context, issues),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                warningCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                size: 16,
                color: warningCount > 0
                    ? scheme.onErrorContainer
                    : scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                '${issues.length} space ${issues.length == 1 ? 'note' : 'notes'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: warningCount > 0
                      ? scheme.onErrorContainer
                      : scheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssuesSheet(BuildContext context, List<SpaceValidationIssue> issues) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Space Validation',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Based on this room\'s estimated dimensions — advisory only, '
                'nothing here blocks placement.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _IssueTile(issue: issues[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  final SpaceValidationIssue issue;
  const _IssueTile({required this.issue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWarning = issue.severity == SpaceIssueSeverity.warning;
    return Card(
      color: isWarning ? scheme.errorContainer : scheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
              size: 18,
              color: isWarning ? scheme.onErrorContainer : scheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isWarning ? scheme.onErrorContainer : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    issue.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isWarning ? scheme.onErrorContainer : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
