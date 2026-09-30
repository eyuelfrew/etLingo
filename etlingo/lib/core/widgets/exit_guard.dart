import 'package:flutter/material.dart';
import '../ui/et_strings.dart';

/// Blocks a single back at the root: first press shows a toast,
/// second press (within 2s) allows the system to pop / close the app.
class ExitGuard extends StatefulWidget {
  final Widget child;
  const ExitGuard({super.key, required this.child});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  bool _armed = false;

  void _arm() {
    if (_armed) return;
    setState(() => _armed = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(EtStrings.pressBackAgain),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _armed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _armed,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Nested route (e.g. Curriculum pushed on top) → just go back.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        _arm();
      },
      child: widget.child,
    );
  }
}
