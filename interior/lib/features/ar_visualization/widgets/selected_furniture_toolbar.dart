import 'package:flutter/material.dart';
import '../models/placed_furniture.dart';

class SelectedFurnitureToolbar extends StatelessWidget {
  final PlacedFurniture selected;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onScaleUp;
  final VoidCallback onScaleDown;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const SelectedFurnitureToolbar({
    super.key,
    required this.selected,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onScaleUp,
    required this.onScaleDown,
    required this.onReplace,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withOpacity(0.96),
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected.furniture.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  tooltip: 'Deselect',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.rotate_left,
                  label: 'Rotate',
                  onPressed: onRotateLeft,
                ),
                _ToolButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  onPressed: onRotateRight,
                ),
                _ToolButton(
                  icon: Icons.zoom_out,
                  label: 'Smaller',
                  onPressed: onScaleDown,
                ),
                _ToolButton(
                  icon: Icons.zoom_in,
                  label: 'Bigger',
                  onPressed: onScaleUp,
                ),
                _ToolButton(
                  icon: Icons.swap_horiz,
                  label: 'Replace',
                  onPressed: onReplace,
                ),
                _ToolButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: scheme.error,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: onPressed, icon: Icon(icon, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}
