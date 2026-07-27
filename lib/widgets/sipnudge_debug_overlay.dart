//
// sipnudge_debug_overlay.dart — SipNudge BLE breadcrumb viewer
// Date: 2026-07-22
//
// CHANGELOG / SUMMARY (2026-07-22):
// - New file. Adds a floating debug button visible on EVERY screen
//   (bottom-right bug icon). Tap it → dark panel showing all dbg_*
//   breadcrumbs read from the native app group via the
//   com.sipnudge.sipnudge/native_ble MethodChannel handlers that
//   AppDelegate_fixed_v2.swift provides (getDebugBreadcrumbs /
//   clearDebugBreadcrumbs).
// - Panel buttons: Refresh, Copy (puts the full text on the clipboard —
//   paste it into chat, no screenshot needed), Clear, Close.
// - Deliberately avoids Navigator/showDialog so it can be mounted above
//   MaterialApp's Navigator via the `builder:` hook.
//
// INTEGRATION — exactly one line in main.dart, inside MaterialApp:
//
//   MaterialApp(
//     builder: (context, child) => SipnudgeDebugOverlay(child: child!),
//     // ...everything else unchanged
//   )
//
// If your MaterialApp ALREADY has a builder, wrap its existing return
// value: builder: (c, child) => SipnudgeDebugOverlay(child: existing).
//
// Before an App Store build: set `enabled = false` below (or gate on
// kDebugMode). The Swift-side handlers are harmless to ship.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SipnudgeDebugOverlay extends StatefulWidget {
  const SipnudgeDebugOverlay({super.key, required this.child});

  final Widget child;

  /// Kill switch for release builds.
  static const bool enabled = true;

  static final GlobalKey overlayKey = GlobalKey();

  static void show() {
    (overlayKey.currentState as _SipnudgeDebugOverlayState?)?._openPanel();
  }

  static void toggle() {
    (overlayKey.currentState as _SipnudgeDebugOverlayState?)?._toggle();
  }

  @override
  State<SipnudgeDebugOverlay> createState() => _SipnudgeDebugOverlayState();
}

class _SipnudgeDebugOverlayState extends State<SipnudgeDebugOverlay> {
  static const _ble = MethodChannel('com.sipnudge.sipnudge/native_ble');

  bool _open = false;
  String _text = 'Loading…';

  void _openPanel() {
    setState(() => _open = true);
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final raw = await _ble.invokeMethod('getDebugBreadcrumbs');
      final map = Map<String, String>.from(raw as Map);
      if (map.isEmpty) {
        setState(() => _text = '(no dbg_* keys yet — run a sync first)');
        return;
      }
      final keys = map.keys.toList()..sort();
      setState(
          () => _text = keys.map((k) => '$k\n  ${map[k]}').join('\n\n'));
    } on MissingPluginException {
      setState(() => _text =
          'getDebugBreadcrumbs handler not found.\nAppDelegate_fixed_v2.swift is NOT in this build.');
    } on PlatformException catch (e) {
      setState(() => _text = 'Handler error: ${e.message}');
    }
  }

  Future<void> _clear() async {
    try {
      await _ble.invokeMethod('clearDebugBreadcrumbs');
    } catch (_) {}
    await _refresh();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _refresh();
  }

  Widget _btn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(label,
            style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SipnudgeDebugOverlay.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,

          // ── Breadcrumb panel ──────────────────────────────────────────
          if (_open)
            Positioned(
              left: 12,
              right: 12,
              bottom: 96,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  color: const Color(0xE6000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('BLE breadcrumbs',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        _btn('Refresh', _refresh),
                        _btn('Copy', () {
                          Clipboard.setData(ClipboardData(text: _text));
                        }),
                        _btn('Clear', _clear),
                        _btn('Close', _toggle),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.35,
                            fontFamily: 'Menlo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Floating debug button (every screen, bottom-right) ────────
          Positioned(
            right: 16,
            bottom: 34,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _open
                      ? const Color(0xFF1565C0)
                      : const Color(0xB3000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bug_report,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
