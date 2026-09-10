import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../furniture/repositories/furniture_repository.dart';
import '../repositories/design_repository.dart';

/// Bundles the three repositories the comparison loader needs, so the
/// loader function itself stays a plain function rather than a
/// Riverpod provider (it's a one-shot fetch used from a FutureBuilder).
class DesignComparisonDeps {
  final DesignRepository designRepo;
  final FurnitureRepository furnitureRepo;
  final RealtimeDatabaseService db;

  const DesignComparisonDeps({
    required this.designRepo,
    required this.furnitureRepo,
    required this.db,
  });
}
