import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Renders a single GLB/glTF model. This widget is only ever built by
/// [Furniture3DPreviewScreen] — never by the catalog grid or details
/// screen — so a model is only fetched/decoded when the user explicitly
/// asks to view it in 3D, never preemptively (Sec. 16: "Do not load
/// every 3D model simultaneously. Load models only when required.").
///
/// Uses the furniture's existing 2D thumbnail as a `poster` image, so
/// something meaningful is on screen immediately while the (often
/// several-MB) model streams in behind it.
class Model3DViewer extends StatelessWidget {
  final String modelUrl;
  final String? posterImageUrl;
  final String alt;

  const Model3DViewer({
    super.key,
    required this.modelUrl,
    required this.alt,
    this.posterImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ModelViewer(
      src: modelUrl,
      alt: alt,
      poster: posterImageUrl,
      ar: false, // AR placement is Phase 12 — this is preview-only.
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      backgroundColor: scheme.surfaceVariant,
      loading: Loading.eager,
    );
  }
}
