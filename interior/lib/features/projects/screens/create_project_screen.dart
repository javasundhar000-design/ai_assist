import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/projects_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  RoomType _roomType = RoomType.livingRoom;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final project =
        await ref.read(createProjectControllerProvider.notifier).create(
              userId: user.uid,
              projectName: _nameController.text.trim(),
              roomType: _roomType,
              description: _descriptionController.text.trim(),
            );

    if (project != null && mounted) {
      // Room scanning is implemented in Phase 7 — for now land back on
      // the project details screen once that phase lands.
      context.go('/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${project.projectName}" created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createProjectControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(createProjectControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not create project. Please try again.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New Project')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                  validator: (v) =>
                      Validators.required(v, field: 'Project name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomType>(
                  value: _roomType,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: RoomType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _roomType = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Project'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
