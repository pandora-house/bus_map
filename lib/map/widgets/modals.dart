import 'package:flutter/material.dart';

class Modals {
  static Future<void> _showModal(BuildContext context) {
    return showModalBottomSheet(
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          margin: EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 0),
                color: Colors.grey,
                blurRadius: 20.0,
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showBus(BuildContext context) {
    return _showModal(context);
  }

  static Future<void> showBusStop(BuildContext context) {
    return _showModal(context);
  }
}