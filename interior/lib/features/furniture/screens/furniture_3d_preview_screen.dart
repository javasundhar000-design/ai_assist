import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/furniture_provider.dart';
import '../widgets/model_3d_viewer.dart';

class Furniture3DPreviewScreen extends ConsumerStatefulWidget {
  final String furnitureId;
  const Furniture3DPreviewScreen({super.key, required this.furnitureId});

  @override
  ConsumerState<Furniture3DPreviewScreen> createState() =>
      _Furniture3DPreviewScreenState();
}

class _Furniture3DPreviewScreenState
    extends ConsumerState<Furniture3DPreviewScreen> {
  // Bumping this key re-mounts the ModelViewer (and so re-attempts the
  // load) without navigating away — used by the manual "Reload" action.
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(furnitureRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Preview'),
        actions: [
          IconButton(
            tooltip: 'Reload model',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _reloadKey++),
          ),
        ],
      ),
      body: FutureBuilder(
        future: repo.getById(widget.furnitureId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(label: 'Loading item…');
          }
          final item = snapshot.data;
          if (item == null) {
            return const AppErrorView(message: 'Furniture item not found.');
          }
          if (item.modelUrl.isEmpty) {
            // Sec. 29: "3D model unavailable" — handled gracefully, no crash.
            return AppErrorView(
              message:
                  '${item.name} doesn\'t have a 3D model available yet.',
            );
          }
          return Model3DViewer(
            key: ValueKey('${item.id}_$_reloadKey'),
            modelUrl: item.modelUrl,
            posterImageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
            alt: item.name,
          );
        },
      ),
    );
  }
}
