import 'package:flutter/material.dart';

import '../../theme/campus_colors.dart';
import '../../widgets/friends/friendship_section.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: campusBackground,
      child: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 90, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amigos',
                style: TextStyle(
                  color: campusInk,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 24),
              FriendshipSection(),
            ],
          ),
        ),
      ),
    );
  }
}
