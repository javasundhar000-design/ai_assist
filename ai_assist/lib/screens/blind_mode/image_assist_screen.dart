import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/openrouter_service.dart';
import '../../services/session_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/feature_button.dart';
import '../auth/welcome_screen.dart';

enum AssistFeature {
  full('Full Analysis', Icons.auto_awesome, AssistPrompts.fullAnalysis),
  text('Read Text', Icons.text_fields, AssistPrompts.textRecognition),
  objects('Objects', Icons.category, AssistPrompts.objectRecognition),
  scene('Scene', Icons.landscape, AssistPrompts.sceneUnderstanding),
  currency('Currency', Icons.payments, AssistPrompts.currencyIdentification),
  medicine('Medicine', Icons.medication, AssistPrompts.medicineLabel);

  final String label;
  final IconData icon;
  final String prompt;
  const AssistFeature(this.label, this.icon, this.prompt);
}

class ImageAssistScreen extends StatefulWidget {
  final String familyUid;
  final UserProfile profile;

  const ImageAssistScreen({super.key, required this.familyUid, required this.profile});

  @override
  State<ImageAssistScreen> createState() => _ImageAssistScreenState();
}

class _ImageAssistScreenState extends State<ImageAssistScreen> {
  final ImagePicker _picker = ImagePicker();
  final OpenRouterService _openRouter = OpenRouterService();

  File? _selectedImage;
  String _result = '';
  bool _loading = false;
  AssistFeature _feature = AssistFeature.full;

  Future<void> _logout() async {
    await SessionService.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() {
      _selectedImage = File(image.path);
      _result = '';
    });
    // Immediately analyze after capture — a blind user shouldn't have to
    // find a separate "Analyze" button after taking the photo.
    _analyzeImage();
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() {
      _selectedImage = File(image.path);
      _result = '';
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      TtsService.instance.speak('Please take or choose a photo first.');
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
    });
    TtsService.instance.speak('Analyzing image, please wait.');

    try {
      final result = await _openRouter.analyzeImage(
        imageFile: _selectedImage!,
        task: _feature.prompt,
      );
      setState(() => _result = result);
      TtsService.instance.speak(result);
    } catch (e) {
      final message = 'Something went wrong: ${e.toString()}';
      setState(() => _result = message);
      TtsService.instance.speak('Sorry, image processing failed.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blind Mode — ${widget.profile.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out'),
        ],
      ),
      floatingActionButton: EmergencyButton(familyUid: widget.familyUid, profile: widget.profile),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Feature selector
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AssistFeature.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = AssistFeature.values[i];
                    return FeatureButton(
                      label: f.label,
                      icon: f.icon,
                      selected: f == _feature,
                      onTap: () => setState(() => _feature = f),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Image preview
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Icon(Icons.image, size: 90, color: Colors.grey),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _loading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose From Gallery'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _loading ? null : _analyzeImage,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Analyzing...' : 'Analyze Image'),
              ),
              const SizedBox(height: 24),

              if (_result.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy),
                            const SizedBox(width: 10),
                            const Text('AI Result',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              tooltip: 'Read aloud again',
                              onPressed: () => TtsService.instance.speak(_result),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_result, style: const TextStyle(fontSize: 17, height: 1.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
