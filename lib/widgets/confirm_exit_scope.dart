import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmExitScope extends StatefulWidget {
  final Widget child;

  const ConfirmExitScope({super.key, required this.child});

  @override
  State<ConfirmExitScope> createState() => _ConfirmExitScopeState();
}

class _ConfirmExitScopeState extends State<ConfirmExitScope> {
  bool _showingDialog = false;

  Future<void> _confirmExit() async {
    if (_showingDialog) return;
    _showingDialog = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do SQEducaPlay?'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar no app'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    _showingDialog = false;
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: widget.child,
    );
  }
}
