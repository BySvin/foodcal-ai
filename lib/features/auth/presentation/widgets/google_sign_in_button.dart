import 'package:flutter/material.dart';

/// "Continue with Google" button. Uses a lightweight lettermark instead of
/// a bundled brand asset — swap for the official Google logo asset before
/// a store submission that requires exact brand guideline compliance.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GoogleLettermark(),
                const SizedBox(width: 12),
                Text('Continue with Google', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
    );
  }
}

class _GoogleLettermark extends StatelessWidget {
  const _GoogleLettermark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
