import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      title,
                      style: tokens.titleLarge,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onBackPressed != null)
                  Positioned(
                    left: 0,
                    child: Tooltip(
                      message: 'Volver',
                      child: Semantics(
                        button: true,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onBackPressed,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.marilin.fill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tokens.border,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14,
                                color: tokens.brandNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (trailing != null) Positioned(right: 0, child: trailing!),
              ],
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle!,
                style: tokens.subtitle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Divider(color: tokens.border, height: 1),
      ],
    );
  }
}
