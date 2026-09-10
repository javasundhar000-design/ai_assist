import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/room_and_design_models.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../furniture/providers/furniture_provider.dart';
import '../repositories/design_repository.dart';
import '../services/design_comparison_repository_deps.dart';

final designRepositoryProvider = Provider<DesignRepository>((ref) {
  return DesignRepository(ref.watch(realtimeDatabaseServiceProvider));
});

/// Live list of every design (active + soft-deleted) for a project.
final projectDesignsProvider =
    StreamProvider.family<List<DesignModel>, String>((ref, projectId) {
  return ref.watch(designRepositoryProvider).watchDesignsForProject(projectId);
});

/// Bundles the repositories Design Comparison (Phase 15) needs for its
/// one-shot bundle loader.
final designComparisonDepsProvider = Provider<DesignComparisonDeps>((ref) {
  return DesignComparisonDeps(
    designRepo: ref.watch(designRepositoryProvider),
    furnitureRepo: ref.watch(furnitureRepositoryProvider),
    db: ref.watch(realtimeDatabaseServiceProvider),
  );
});

/// Handoff for the "Continue in AR" / Edit flow: Design History sets
/// this right before navigating to the AR screen, which reads it once,
/// queues the listed furniture for re-placement, then clears it. Not a
/// URL param because a list of FurnitureModel doesn't serialize
/// cleanly into a route path.
final designEditHandoffProvider =
    StateProvider.autoDispose<DesignEditHandoff?>((ref) => null);

class DesignEditHandoff {
  final String designName;
  final List<FurnitureModel> items;
  const DesignEditHandoff({required this.designName, required this.items});
}
