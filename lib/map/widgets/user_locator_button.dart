import 'package:flutter/material.dart';

class UserLocatorButton extends StatelessWidget {
  const UserLocatorButton({
    super.key,
    required this.onTap,
  });

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 60),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                spreadRadius: 0,
                color: Colors.grey,
              )
            ]
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Image.asset('assets/user_locator_icon.png'),
          ),
        ),
      ),
    );
  }
}
