import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'recommendations_screen.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  bool _analyzing = false;

  final _attributes = const [
    ('Face Shape', 'Oval', Icons.face_retouching_natural_outlined),
    ('Skin Tone', 'Medium', Icons.palette_outlined),
    ('Body Type', 'Inverted Triangle', Icons.accessibility_new_outlined),
    ('Height (Approx.)', "5'5\"", Icons.straighten_outlined),
  ];

  void _reanalyze() {
    setState(() => _analyzing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _analyzing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('AI Analysis', style: AppTextStyles.h1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _analyzing ? AppColors.violet : AppColors.success,
                      width: 2,
                    ),
                  ),
                ),
                FashionImagePlaceholder(
                  accent: AppColors.violet,
                  icon: Icons.face,
                  height: 130,
                  width: 130,
                  borderRadius: 65,
                ),
                if (_analyzing)
                  const SizedBox(
                    width: 148,
                    height: 148,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violet),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AiBadge(
              label: _analyzing ? 'Scanning...' : 'AI analysis completed',
              icon: _analyzing ? Icons.autorenew : Icons.check_circle_outline,
            ),
            const SizedBox(height: 28),

            ..._attributes.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AuraCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.violet.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Icon(a.$3, color: AppColors.violet, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(a.$1, style: AppTextStyles.body)),
                        Text(a.$2, style: AppTextStyles.bodyStrong),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: SectionHeader(title: 'Best Colors')),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: MockData.bestColors
                  .map((c) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.4),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: _analyzing ? 'Analyzing...' : 'View My Recommendations',
              icon: Icons.auto_awesome,
              onPressed: _analyzing
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
                      ),
            ),
            const SizedBox(height: 12),
            OutlineActionButton(
              label: _analyzing ? 'Analyzing...' : 'Re-analyze',
              icon: Icons.refresh,
              onPressed: _analyzing ? null : _reanalyze,
            ),
          ],
        ),
      ),
    );
  }
}
