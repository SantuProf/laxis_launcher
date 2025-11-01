import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wallpaper/wallpaper_notifier.dart';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;

  AppInfo({required this.name, required this.packageName, this.icon});
}

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Use a subtle, theme-aware glow for overscroll that's less obtrusive than the default.
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
  color: Color.lerp(Colors.transparent, Theme.of(context).colorScheme.primary, 0.12) ?? Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()),
      child: child,
    );
  }
}

class AppScreen extends StatefulWidget {
  final bool scrollToTop;
  const AppScreen({super.key, this.scrollToTop = false});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  static const MethodChannel _appsChannel = MethodChannel('laxis/apps');
  static const EventChannel _appsEvents = EventChannel('laxis/appEvents');

  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  // UI state and controllers
  final ScrollController _scrollController = ScrollController();
  int _columns = 4;
  double _iconSize = 48.0;
  double _pullDownDy = 0.0;
  bool _poppedByPull = false;
  StreamSubscription? _eventsSub;
  int? _wallpaperColorValue;
  String? _wallpaperPath;

  @override
  void initState() {
    super.initState();
    _listenForEvents();
    _loadApps();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    // Listen to wallpaper changes
    WallpaperNotifier().addListener(_onWallpaperChanged);
    // Load initial wallpaper
    await WallpaperNotifier().loadSavedWallpaper();
    _onWallpaperChanged();
  }

  void _onWallpaperChanged() {
    if (!mounted) return;
    setState(() {
      _wallpaperPath = WallpaperNotifier().wallpaperPath;
      _wallpaperColorValue = WallpaperNotifier().wallpaperColorValue;
    });
  }

  @override
  void dispose() {
    WallpaperNotifier().removeListener(_onWallpaperChanged);
    _eventsSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenForEvents() {
    _eventsSub = _appsEvents.receiveBroadcastStream().listen((event) {
      _loadApps();
    }, onError: (err) {
      // ignore
    });
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> result = await _appsChannel.invokeMethod('getInstalledApps');
      final List<AppInfo> apps = result.map((dynamic item) {
        final Map map = Map.of(item as Map);
        final String name = map['name'] ?? '';
        final String package = map['package'] ?? '';
        final String? iconBase64 = map['icon'];
        Uint8List? icon;
        if (iconBase64 != null) {
          try {
            icon = base64Decode(iconBase64);
          } catch (_) {
            icon = null;
          }
        }
        return AppInfo(name: name, packageName: package, icon: icon);
      }).cast<AppInfo>().toList();

      setState(() {
        _apps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
      // If caller requested, scroll to top after the grid builds
      if (widget.scrollToTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutBack,
              );
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _apps
          .where((app) =>
              app.name.toLowerCase().contains(query.toLowerCase()) ||
              app.packageName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _launchApp(String packageName) async {
    try {
      await _appsChannel.invokeMethod('launchApp', {'package': packageName});
    } catch (e) {
      // ignore
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LauncherSettings(
          initialColumns: _columns,
          initialIconSize: _iconSize,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _columns = result['columns'] as int;
        _iconSize = result['iconSize'] as double;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // wallpaper background: color takes precedence
            if (_wallpaperColorValue != null)
              Positioned.fill(child: Container(color: Color(_wallpaperColorValue!))),
            if (_wallpaperColorValue == null && _wallpaperPath != null)
              Positioned.fill(child: Image.file(File(_wallpaperPath!), fit: BoxFit.cover)),

            // main content
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withAlpha(230),
                      Theme.of(context).colorScheme.surface.withAlpha(200),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'Laxis',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _openSettings,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                Expanded(
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  if (notification.metrics.pixels <= 0 && (notification.scrollDelta ?? 0) < 0) {
                                    _pullDownDy += -(notification.scrollDelta ?? 0);
                                    if (_pullDownDy > 120 && !_poppedByPull) {
                                      _poppedByPull = true;
                                      Navigator.of(context).pop();
                                    }
                                  }
                                } else if (notification is ScrollEndNotification || notification is ScrollUpdateNotification && notification.metrics.pixels > 0) {
                                  _pullDownDy = 0.0;
                                  _poppedByPull = false;
                                }
                                return false;
                              },
                              child: ScrollConfiguration(
                                behavior: SmoothScrollBehavior(),
                                child: Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(8),
                                  thickness: 8,
                                  child: GridView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _columns,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: _filteredApps.length,
                                    itemBuilder: (context, index) {
                                      final app = _filteredApps[index];
                                      return _AppIcon(
                                        app: app,
                                        onTap: () => _launchApp(app.packageName),
                                        iconSize: _iconSize,
                                      );
                                    },
                                  ),
                                ),
                              ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withAlpha(40),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _filterApps,
                                      decoration: InputDecoration(
                                        hintText: 'Search apps...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.surface.withAlpha(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _AppIcon extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final double iconSize;
  const _AppIcon({required this.app, required this.onTap, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (app.icon != null) {
      iconWidget = Image.memory(
        app.icon!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else {
      iconWidget = Icon(Icons.android, size: iconSize * 0.67, color: Theme.of(context).colorScheme.primary);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withAlpha(51),
                  Theme.of(context).colorScheme.primary.withAlpha(25),
                ],
              ),
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Center(child: iconWidget)),
          ),
          const SizedBox(height: 6),
          Text(
            app.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
