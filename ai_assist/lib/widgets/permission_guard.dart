import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../models/permission.dart';
import 'error_view.dart';

/// Wraps a screen body and refuses to render it unless the current user has
/// [required]. This is a UX safety net for deep-linked or manually-typed
/// routes — the backend independently rejects the underlying API calls
/// regardless of what this widget does (spec §43: "Frontend hiding is NOT
/// sufficient").
class PermissionGuard extends ConsumerWidget {
  final Permission required;
  final Widget child;

  const PermissionGuard({super.key, required this.required, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.has(required)) {
      return const ErrorView(
        message: 'You do not have permission to access this feature.',
      );
    }
    return child;
  }
}
