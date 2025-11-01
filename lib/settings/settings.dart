import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laxis/wallpaper/wallpaper.dart';

class LauncherSettings extends StatefulWidget {
  final int initialColumns;
  final double initialIconSize;

  const LauncherSettings({
    super.key,
    this.initialColumns = 4,
    this.initialIconSize = 48.0,
  });

  @override
  State<LauncherSettings> createState() => _LauncherSettingsState();
}

class _LauncherSettingsState extends State<LauncherSettings> {
  late int _gridColumns;
  late double _iconSize;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    _gridColumns = widget.initialColumns;                                                                                                                                                   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          _iconSize = widget.initialIconSize;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1929),
            Color(0xFF0F2942),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Launcher Settings'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'columns': _gridColumns,
                  'iconSize': _iconSize,
                });
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Phone Settings Section
            Card(
              color: const Color(0xFF132F4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Phone Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.system_update, color: Colors.white70),
                    title: const Text('System Settings', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      // Open Android system settings (generic)
                      try {
                        if (Platform.isAndroid) {
                          await MethodChannel('laxis/apps').invokeMethod('openSystemSettings');
                        } else {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not available on this platform')));
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open settings: $e')));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.wallpaper, color: Colors.white70),
                    title: const Text('Wallpaper', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Open the in-app wallpaper screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WallpaperScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_filled, color: Colors.white70),
                    title: const Text('Change default launcher', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Set which app opens when you press Home', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    onTap: () async {
                      try {
                        if (Platform.isAndroid) {
                          await MethodChannel('laxis/apps').invokeMethod('openHomeSettings');
                        } else {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not available on this platform')));
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open default launcher settings: $e')));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Launcher Settings Section
            Card(
              color: const Color(0xFF132F4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Launcher Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grid Columns', style: TextStyle(color: Colors.white70)),
                        Slider(
                          value: _gridColumns.toDouble(),
                          min: 3,
                          max: 6,
                          divisions: 3,
                          label: _gridColumns.toString(),
                          onChanged: (value) {
                            setState(() {
                              _gridColumns = value.round();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Icon Size', style: TextStyle(color: Colors.white70)),
                        Slider(
                          value: _iconSize,
                          min: 32,
                          max: 72,
                          label: '${_iconSize.round()}',
                          onChanged: (value) {
                            setState(() {
                              _iconSize = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Show App Labels', style: TextStyle(color: Colors.white)),
                          value: _showLabels,
                          onChanged: (value) {
                            setState(() {
                              _showLabels = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}