import 'package:flutter/material.dart';
import 'package:omit/notifiers/error_notifier_mixin.dart';
import 'package:provider/provider.dart';

/// Widget that listens to a [ErrorNotifierMixin] and shows a SnackBar on error.
class ErrorListener<T extends ErrorNotifierMixin> extends StatefulWidget {
  const ErrorListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<ErrorListener<T>> createState() => _ErrorListenerState<T>();
}

class _ErrorListenerState<T extends ErrorNotifierMixin>
    extends State<ErrorListener<T>> {
  @override
  void initState() {
    super.initState();
    context.read<T>().addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    context.read<T>().removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    if (!mounted) return;
    final notifier = context.read<T>();
    final error = notifier.errorMessage;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      notifier.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
