import 'package:flutter/material.dart';

import '../pages/access_choice_page.dart';
import '../services/session_service.dart';

class ConfirmExitScope extends StatefulWidget {
  final Widget child;
  final WidgetBuilder? startPageBuilder;

  const ConfirmExitScope({
    super.key,
    required this.child,
    this.startPageBuilder,
  });

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
        content: const Text('Deseja sair da conta e voltar ao inicio?'),
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
      await SessionService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: widget.startPageBuilder ?? (_) => const AccessChoicePage(),
        ),
        (_) => false,
      );
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
