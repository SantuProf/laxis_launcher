import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'appscreen.dart';
import 'wallpaper/wallpaper_notifier.dart';
import 'widgets/widget.dart';
import 'widgets/widgets_manager.dart';

/// A clean Android-like homescreen placeholder.
/// Swipe up from the bottom to reveal the app list.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Track vertical drag to open AppScreen on a deliberate upward swipe
  double _dragDy = 0.0;

  // Animation for the swipe-up affordance
  late final AnimationController _chevronController;
  late final Animation<double> _chevronTranslate;
  // Notification shade controller (pull-down from top)
  late final AnimationController _shadeController;
  late final Animation<double> _shadeTranslate;
  final double _shadeHeight = 420.0;
  List<Map<String, String>> _notifications = [];
  // Interactive drag animation controller (0.0 = closed, 1.0 = fully opened)
  late final AnimationController _dragController;
  late final Animation<double> _dragTranslate;
  late final Animation<double> _dragScale;
  late final Animation<double> _scrimOpacity;

  // Wallpaper state
  String? _wallpaperPath;
  int? _wallpaperColorValue;
  List<WidgetItem> _placedWidgets = [];
  final GlobalKey _homeAreaKey = GlobalKey();

  Future<void> _loadWallpaper() async {
    // Listen to wallpaper changes
    WallpaperNotifier().addListener(_onWallpaperChanged);
    // Load initial wallpaper
    await WallpaperNotifier().loadSavedWallpaper();
    _onWallpaperChanged();
  }

  void _onWidgetsChanged() {
    if (!mounted) return;
    setState(() {
      _placedWidgets = WidgetsManager().items;
    });
  }

  void _onWallpaperChanged() {
    if (!mounted) return;
    setState(() {
      _wallpaperPath = WallpaperNotifier().wallpaperPath;
      _wallpaperColorValue = WallpaperNotifier().wallpaperColorValue;
    });
  }

  // Wallpaper picker removed: access via WallpaperScreen elsewhere if needed.

  void _showWidgetPopup() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Builder(
            builder: (context) {
              final popupHeight = MediaQuery.of(context).size.height * 0.70;
              return SizedBox(
                width: double.infinity,
                height: popupHeight,
                child: AppBackground(
                  // Use the new WidgetsPanel so the popup shows clock, weather and options
                  child: const WidgetsPanel(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Load saved wallpaper
    _loadWallpaper();
    // Listen for widget placement changes
    WidgetsManager().addListener(_onWidgetsChanged);
    // initialize local copy
    _placedWidgets = WidgetsManager().items;
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chevronTranslate = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
    // loop the animation back and forth
    _chevronController.repeat(reverse: true);

    // Drag controller controls the interactive transition when user drags up
    // Use a slightly longer duration and an easeOutBack curve for a snappier,
    // natural-feeling lift when the user swipes up.
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _dragTranslate = Tween<double>(
      begin: 0.0,
      end: -420.0,
    ).animate(CurvedAnimation(parent: _dragController, curve: Curves.easeOutBack));
    _dragScale = Tween<double>(
      begin: 1.0,
      end: 0.985,
    ).animate(CurvedAnimation(parent: _dragController, curve: Curves.easeOutBack));
    _scrimOpacity = Tween<double>(
      begin: 0.0,
      end: 0.36,
    ).animate(CurvedAnimation(parent: _dragController, curve: Curves.easeOutBack));

    // Notification shade init
    _shadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shadeTranslate = Tween<double>(begin: -_shadeHeight, end: 0.0).animate(CurvedAnimation(parent: _shadeController, curve: Curves.easeOut));

    // sample notifications
    _notifications = List.generate(6, (i) {
      return {
        'title': 'Message from Contact ${i + 1}',
        'body': 'This is a preview of message ${i + 1}. Tap to open.',
        'time': '${8 + i}:${(i * 7) % 60}'.padLeft(2, '0'),
      };
    });
  }

  @override
  void dispose() {
    WallpaperNotifier().removeListener(_onWallpaperChanged);
    WidgetsManager().removeListener(_onWidgetsChanged);
    _chevronController.dispose();
    _dragController.dispose();
    _shadeController.dispose();
    super.dispose();
  }

  Future<void> _showAppList(BuildContext context, {bool scrollToTop = false}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 480),
  reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppScreen(scrollToTop: scrollToTop),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Incoming slide from bottom + subtle scale + fade
          // Slightly bouncy incoming motion for a polished feel
          final slideTween = Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutBack));
          final scaleTween = Tween<double>(
            begin: 0.98,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutBack));
          final fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn));

          // Scrim that fades in behind the incoming page
          final scrim = FadeTransition(
            opacity: animation.drive(
              Tween(
                begin: 0.0,
                end: 0.36,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: Container(color: Colors.black),
          );

          final incoming = SlideTransition(
            position: animation.drive(slideTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            ),
          );

          return Stack(
            children: [
              // scrim behind the incoming route
              Positioned.fill(child: scrim),
              incoming,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Wallpaper background: color takes precedence over image
          if (_wallpaperColorValue != null)
            Positioned.fill(
              child: Container(color: Color(_wallpaperColorValue!)),
            )
          else if (_wallpaperPath != null)
            Positioned.fill(
              child: Image.file(File(_wallpaperPath!), fit: BoxFit.cover),
            ),
          // Main content with interactive drag animation
          GestureDetector(
            onDoubleTap: _showWidgetPopup,
            onVerticalDragStart: (_) {
              _dragDy = 0.0;
            },
            onVerticalDragUpdate: (details) {
              // accumulate dy; upward drag has negative dy
              _dragDy += details.delta.dy;
              // Drive controller value from 0..1 for a 200px drag range
              final progress = (-_dragDy / 200.0).clamp(0.0, 1.0);
              _dragController.value = progress;
            },
            onVerticalDragEnd: (details) async {
              final velocity = details.velocity.pixelsPerSecond.dy;
              // if user flung upward or dragged past halfway, complete transition
              if (_dragController.value > 0.5 || velocity < -800) {
                // Start the finish animation but don't await it — push the app list immediately
                _dragController.animateTo(1.0, curve: Curves.easeOut);
                // Push the app list right away to reduce perceived latency
                await _showAppList(context);
                // when returning, reset the controller (await to ensure smooth rollback)
                if (mounted) {
                  await _dragController.animateTo(0.0, curve: Curves.easeOut);
                }
              } else {
                // otherwise roll back
                await _dragController.animateBack(0.0, curve: Curves.easeOut);
                _dragDy = 0.0;
              }
            },
            child: SafeArea(
              key: _homeAreaKey,
              child: AnimatedBuilder(
                animation: _dragController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // scrim behind content during drag
                      if (_dragController.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              color: Color.lerp(
                                Colors.transparent,
                                Colors.black,
                                _scrimOpacity.value,
                              ),
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(0, _dragTranslate.value),
                        child: Transform.scale(
                          scale: _dragScale.value,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
                child: Column(
                  children: [
                    // Top spacer (clock and date removed)
                    const SizedBox(height: 12),

                    // Top/center content area (reduced) — this pushes app affordance and dock a bit higher
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Homescreen-placed widgets row (if any)
                          if (_placedWidgets.isNotEmpty)
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                scrollDirection: Axis.horizontal,
                                itemCount: _placedWidgets.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = _placedWidgets[index];
                                  return Container(
                                    width: 220,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Widget preview
                                        Align(
                                          alignment: Alignment.center,
                                          child: _buildPreviewForType(item.type),
                                        ),
                                        // Remove button
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                                            onPressed: () => WidgetsManager().removeWidget(item.id),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Fill remaining vertical space
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),

                    // Small animated swipe-up affordance (above search bar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _showAppList(context, scrollToTop: true),
                          child: AnimatedBuilder(
                            animation: _chevronController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _chevronTranslate.value),
                                child: Opacity(
                                  opacity: 0.95,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        size: 28,
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(200),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 36,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(40),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Bottom search bar (frosted glass) — positioned just above the dock
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: 10.0,
                            sigmaY: 10.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withAlpha(8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Search apps or settings',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(179),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.mic,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    153,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Dock
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Icon(Icons.phone),
                          const Icon(Icons.message),
                          // replaced the 3rd app icon with a widget icon that opens the widget popup
                          GestureDetector(
                            onTap: _showWidgetPopup,
                            child: const Icon(Icons.widgets),
                          ),
                          const Icon(Icons.camera_alt),
                        ],
                      ),
                    ),
                  ],
                ), // end Column (child of AnimatedBuilder)
              ), // end AnimatedBuilder
            ), // end SafeArea
          ), // end GestureDetector
          // Render placed widgets on top and make them draggable via long-press
          for (final item in _placedWidgets)
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                // compute absolute position from normalized coords
                final w = 160.0;
                final h = 110.0;
                final left = (item.posX * constraints.maxWidth) - (w / 2);
                final top = (item.posY * constraints.maxHeight) - (h / 2);
                return Stack(
                  children: [
                    Positioned(
                      left: left.clamp(8.0, constraints.maxWidth - w - 8.0),
                      top: top.clamp(8.0, constraints.maxHeight - h - 8.0),
                      width: w,
                      height: h,
                      child: LongPressDraggable<WidgetItem>(
                        data: item,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.95,
                            child: Container(
                              width: w,
                              height: h,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: _buildPreviewForType(item.type)),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(opacity: 0.4, child: _buildPreviewForType(item.type)),
                        onDragEnd: (details) {
                          // Convert global offset to local within the home area
                          final box = _homeAreaKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local = box.globalToLocal(details.offset + Offset(w / 2, h / 2));
                          final nx = (local.dx / box.size.width).clamp(0.0, 1.0);
                          final ny = (local.dy / box.size.height).clamp(0.0, 1.0);
                          WidgetsManager().updateWidgetPosition(item.id, nx, ny);
                        },
                        child: GestureDetector(
                          onLongPress: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Center(child: _buildPreviewForType(item.type)),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () => WidgetsManager().removeWidget(item.id),
                                    child: const Icon(Icons.close, size: 18, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            // Notification shade (top pull-down)
            AnimatedBuilder(
              animation: _shadeController,
              builder: (context, child) {
                final y = _shadeTranslate.value;
                return Stack(
                  children: [
                    // scrim that closes shade when tapped
                    if (_shadeController.value > 0)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _shadeController.reverse(),
                          child: Container(color: Color.fromRGBO(0, 0, 0, 0.32 * _shadeController.value)),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: y,
                      child: SizedBox(
                        height: _shadeHeight,
                        child: SafeArea(
                          bottom: false,
                          child: AppBackground(
                            borderRadius: 0,
                            blurSigma: 6.0,
                            color: Theme.of(context).cardColor.withAlpha(20),
                            child: Column(
                              children: [
                                // handle
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(90),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _notifications.length,
                                      separatorBuilder: (_, __) => const Divider(height: 12, color: Colors.transparent),
                                      itemBuilder: (context, index) {
                                        final n = _notifications[index];
                                        return ListTile(
                                          leading: CircleAvatar(child: Text(n['title']!.substring(0,1))),
                                          title: Text(n['title']!, style: const TextStyle(color: Colors.white)),
                                          subtitle: Text(n['body']!, style: const TextStyle(color: Colors.white70)),
                                          trailing: Text(n['time']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open: ${n['title']}'))),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewForType(String type) {
    switch (type) {
      case 'Clock':
        return const ClockWidget();
      case 'Weather':
        return const WeatherWidget();
      case 'Calendar':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [Icon(Icons.calendar_today, color: Colors.white70), SizedBox(height: 6), Text('Calendar', style: TextStyle(color: Colors.white70))],
        );
      case 'Note':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [Icon(Icons.note, color: Colors.white70), SizedBox(height: 6), Text('Note', style: TextStyle(color: Colors.white70))],
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.widgets, color: Colors.white70), const SizedBox(height: 6), Text(type, style: const TextStyle(color: Colors.white70))],
        );
    }
  }
}
