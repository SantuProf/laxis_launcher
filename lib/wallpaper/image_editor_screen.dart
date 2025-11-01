import 'dart:io';
import 'package:flutter/material.dart';
import 'wallpaper_notifier.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  
  void _applyAndSave() {
    // Save the edited image as wallpaper
    WallpaperNotifier().updateWallpaper(path: widget.imagePath);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wallpaper'),
        actions: [
          TextButton(
            onPressed: _applyAndSave,
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview area
          Expanded(
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  _contrast, 0, 0, 0, _brightness * 255, // R
                  0, _contrast, 0, 0, _brightness * 255, // G
                  0, 0, _contrast, 0, _brightness * 255, // B
                  0, 0, 0, 1, 0, // A
                ]),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Edit controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(Colors.transparent, Colors.black, 0.1) ?? Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brightness slider
                Row(
                  children: [
                    const Icon(Icons.brightness_6),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _brightness,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (value) => setState(() => _brightness = value),
                      ),
                    ),
                  ],
                ),
                // Contrast slider
                Row(
                  children: [
                    const Icon(Icons.contrast),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: 0.0,
                        max: 2.0,
                        onChanged: (value) => setState(() => _contrast = value),
                      ),
                    ),
                  ],
                ),
                // Saturation slider
                Row(
                  children: [
                    const Icon(Icons.color_lens),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _saturation,
                        min: 0.0,
                        max: 2.0,
                        onChanged: (value) => setState(() => _saturation = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}