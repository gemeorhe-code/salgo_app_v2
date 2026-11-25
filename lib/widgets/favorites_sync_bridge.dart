import 'package:flutter/material.dart';

class FavoritesSyncBridge extends StatefulWidget {
  const FavoritesSyncBridge({
    super.key,
    required this.notifier,
    required this.messengerKey,
    required this.child,
  });

  final ValueNotifier<String?> notifier;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<FavoritesSyncBridge> createState() => _FavoritesSyncBridgeState();
}

class _FavoritesSyncBridgeState extends State<FavoritesSyncBridge> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_showMessage);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_showMessage);
    super.dispose();
  }

  void _showMessage() {
    final String? message = widget.notifier.value;
    if (message == null) return;
    widget.notifier.value = null;
    widget.messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
