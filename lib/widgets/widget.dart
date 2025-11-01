import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets_manager.dart';

/// Reusable background widget that matches the homescreen search bar style by default.
///
/// Usage:
/// ```dart
/// AppBackground(child: ...)
/// ```
/// By default this uses `Theme.of(context).cardColor.withAlpha(18)` with a
/// small rounded radius and subtle shadow. You can override `color` and
/// `borderRadius` if needed.
class AppBackground extends StatelessWidget {
	/// The content to display inside the background.
	final Widget? child;

	/// Optional overlay color painted on top of the blurred background.
	/// Pass `Colors.transparent` (default) for no tint, or a translucent
	/// color like `Theme.of(context).cardColor.withAlpha(18)` if you want a
	/// subtle tint.
	final Color? color;

	/// Blur sigma applied to the backdrop. Defaults to 8.0 for a modest blur.
	final double blurSigma;

	/// Corner radius for clipping the backdrop and container.
	final double borderRadius;

	const AppBackground({
		super.key,
		this.child,
		this.color,
		this.blurSigma = 8.0,
		this.borderRadius = 16.0,
	});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		// Default to fully transparent overlay so underlying wallpaper shows
		// through the blur. Caller can provide a translucent color instead.
		final overlayColor = color ?? Colors.transparent;

		return ClipRRect(
			borderRadius: BorderRadius.circular(borderRadius),
			child: BackdropFilter(
				filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
				child: Container(
					decoration: BoxDecoration(
						color: overlayColor,
						// keep a subtle shadow similar to the search bar when overlay
						// is not fully transparent (alpha > 0)
						boxShadow: overlayColor == Colors.transparent
								? null
								: [
										BoxShadow(
											color: theme.shadowColor.withAlpha(8),
											blurRadius: 8,
											offset: const Offset(0, 4),
										),
									],
					),
					child: child ?? const SizedBox.shrink(),
				),
			),
		);
	}
}

/// Small live clock widget that updates every second.
class ClockWidget extends StatefulWidget {
	final TextStyle? style;
	const ClockWidget({super.key, this.style});

	@override
	State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
	late DateTime _now;
	Timer? _timer;

	@override
	void initState() {
		super.initState();
		_now = DateTime.now();
		_timer = Timer.periodic(const Duration(seconds: 1), (_) {
			if (!mounted) return;
			setState(() {
				_now = DateTime.now();
			});
		});
	}

	@override
	void dispose() {
		_timer?.cancel();
		super.dispose();
	}

	String _formattedTime(DateTime t) {
		final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
		final minute = t.minute.toString().padLeft(2, '0');
		final ampm = t.hour < 12 ? 'AM' : 'PM';
		return '$hour:$minute $ampm';
	}

	@override
	Widget build(BuildContext context) {
			return Text(
				_formattedTime(_now),
				style: widget.style ?? Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white, fontSize: 20),
			);
	}
}

/// Simple placeholder weather widget. Replace with a real API later.
class WeatherWidget extends StatelessWidget {
	final String temperature;
	final String condition;
	const WeatherWidget({super.key, this.temperature = '24°C', this.condition = 'Sunny'});

	@override
	Widget build(BuildContext context) {
		return Column(
			mainAxisSize: MainAxisSize.min,
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				Icon(Icons.wb_sunny, size: 36, color: Colors.amberAccent),
				const SizedBox(height: 6),
				Text(
					temperature,
					style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
				),
				Text(
					condition,
					style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
				),
			],
		);
	}
}

/// Panel shown in the widget popup. Contains clock, weather and widget options.
class WidgetsPanel extends StatelessWidget {
	const WidgetsPanel({super.key});

		void _showAddedSnack(BuildContext context, String name) async {
			// Capture messenger before awaiting to avoid using context across async gaps
			final messenger = ScaffoldMessenger.of(context);
			// Persist the widget to the homescreen via WidgetsManager
			// add at a default relative position near top center
			await WidgetsManager().addWidgetWithPosition(name, 0.5, 0.18);
			messenger.showSnackBar(
				SnackBar(content: Text('$name added to homescreen')),
			);
		}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Padding(
			padding: const EdgeInsets.all(16.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							const Text(
								'Widgets',
								style: TextStyle(
									fontSize: 18,
									fontWeight: FontWeight.w600,
									color: Colors.white,
								),
							),
							IconButton(
								onPressed: () => Navigator.of(context).pop(),
								icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withAlpha(220)),
							),
						],
					),
					const SizedBox(height: 12),

					// Row: Clock + Weather
					Row(
						children: [
							Expanded(
								child: Container(
									padding: const EdgeInsets.all(12),
														decoration: BoxDecoration(
															color: const Color.fromRGBO(255, 255, 255, 0.03),
										borderRadius: BorderRadius.circular(12),
									),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: const [
											ClockWidget(),
											SizedBox(height: 6),
											Text('Local time', style: TextStyle(color: Colors.white70)),
										],
									),
								),
							),
							const SizedBox(width: 12),
							Container(
								padding: const EdgeInsets.all(12),
												decoration: BoxDecoration(
													color: const Color.fromRGBO(255, 255, 255, 0.03),
									borderRadius: BorderRadius.circular(12),
								),
								child: const WeatherWidget(),
							),
						],
					),

					const SizedBox(height: 16),

					const Text('Available widgets', style: TextStyle(color: Colors.white70)),
					const SizedBox(height: 8),

					// Simple grid of widget options
					GridView.count(
						crossAxisCount: 3,
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						mainAxisSpacing: 8,
						crossAxisSpacing: 8,
						children: [
							_buildOption(context, Icons.watch, 'Clock', () => _showAddedSnack(context, 'Clock')),
							_buildOption(context, Icons.wb_sunny, 'Weather', () => _showAddedSnack(context, 'Weather')),
							_buildOption(context, Icons.widgets, 'Small Widget', () => _showAddedSnack(context, 'Small Widget')),
							_buildOption(context, Icons.calendar_today, 'Calendar', () => _showAddedSnack(context, 'Calendar')),
							_buildOption(context, Icons.note, 'Note', () => _showAddedSnack(context, 'Note')),
							_buildOption(context, Icons.settings, 'Settings', () => _showAddedSnack(context, 'Settings')),
						],
					),
				],
			),
		);
	}

	Widget _buildOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
		return GestureDetector(
			onTap: onTap,
			child: Container(
						decoration: BoxDecoration(
							color: const Color.fromRGBO(255, 255, 255, 0.03),
							borderRadius: BorderRadius.circular(12),
						),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(icon, color: Colors.white70),
						const SizedBox(height: 6),
						Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
					],
				),
			),
		);
	}
}

