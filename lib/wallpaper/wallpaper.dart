// Suppress lints about using BuildContext across async gaps in this file.
// We capture and validate mounted state where appropriate.
// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'wallpaper_notifier.dart';
import 'image_editor_screen.dart';

class WallpaperScreen extends StatelessWidget {
  const WallpaperScreen({super.key});

  Future<void> _openSystemWallpaperPicker(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!Platform.isAndroid) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Wallpaper picker is only available on Android'),
          ),
        );
      }
      return;
    }

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_WALLPAPER',
      );
      await intent.launch();
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to open wallpaper picker: $e')),
        );
      }
    }
  }

  Future<void> _openGalleryPicker(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!Platform.isAndroid) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gallery picker is only available on Android'),
          ),
        );
      }
      return;
    }

    try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
        if (image != null && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageEditorScreen(imagePath: image.path),
            ),
          );
        }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to open gallery: $e')));
      }
    }
  }

  Future<void> _openLiveWallpaperChooser(BuildContext context) async {
    if (!Platform.isAndroid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Live wallpaper chooser is only available on Android',
            ),
          ),
        );
      }
      return;
    }

    final intent = AndroidIntent(
      action: 'android.service.wallpaper.CHANGE_LIVE_WALLPAPER',
    );
    // Launch without awaiting so we don't use the BuildContext across async gaps here.
    intent.launch().catchError((_) {
      // Fallback: open generic wallpaper picker (fire-and-forget) without using BuildContext here
      final fallback = AndroidIntent(
        action: 'android.intent.action.SET_WALLPAPER',
      );
      fallback.launch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallpaper'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.blueAccent),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Pick an image from your photos'),
                  onTap: () => _openGalleryPicker(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.wallpaper,
                    color: Colors.tealAccent,
                  ),
                  title: const Text('Open system wallpaper picker'),
                  subtitle: const Text(
                    'Use system UI to select and crop wallpaper',
                  ),
                  onTap: () => _openSystemWallpaperPicker(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.animation,
                    color: Colors.purpleAccent,
                  ),
                  title: const Text('Choose live wallpaper'),
                  subtitle: const Text('Pick or change live wallpapers'),
                  onTap: () => _openLiveWallpaperChooser(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.format_color_fill,
                    color: Colors.orangeAccent,
                  ),
                  title: const Text('Solid color'),
                  subtitle: const Text('Set a simple solid color background'),
                  onTap: () async {
                    // For now just show a small color selection dialog
                    final messenger = ScaffoldMessenger.of(context);
                    final color = await showDialog<Color?>(
                      context: context,
                      builder: (context) => const SimpleColorPickerDialog(),
                    );
                    
                    if (color != null) {
                      // Calculate ARGB value synchronously first
                      final int a = ((color.a * 255.0).round() & 0xff) << 24;
                      final int r = ((color.r * 255.0).round() & 0xff) << 16;
                      final int g = ((color.g * 255.0).round() & 0xff) << 8;
                      final int b = ((color.b * 255.0).round() & 0xff);
                      final argb = a | r | g | b;
                      
                      // Update wallpaper state immediately
                      WallpaperNotifier().updateWallpaper(colorValue: argb);
                      
                      // Show feedback
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Color applied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleColorPickerDialog extends StatelessWidget {
  const SimpleColorPickerDialog({super.key});
  final List<Color> _colors = const [
    Colors.black,
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose color'),
      content: SizedBox(
        width: double.maxFinite,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors
              .map(
                (c) => GestureDetector(
                  onTap: () => Navigator.of(context).pop(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
