import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/avatar_utils.dart';

/// The driver's initials on the brand gradient. Presentational: the same
/// avatar on the route header and on the profile screen, at different sizes.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 54});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = AvatarUtils.getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MarilinColors.brandBlue,
            Color.lerp(MarilinColors.brandBlue, Colors.white, 0.18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: MarilinColors.brandBlue.withValues(alpha: 0.2),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.3,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
