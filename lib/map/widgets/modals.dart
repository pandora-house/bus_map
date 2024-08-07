import 'package:bus_map/map/models/bus_data.dart';
import 'package:bus_map/map/models/bus_stop_data.dart';
import 'package:flutter/material.dart';

class Modals {
  static Future<void> _showModal(BuildContext context, Widget child) {
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
          margin: EdgeInsets.only(top: 3),
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
            ],
          ),
        );
      },
    );
  }

  static Future<void> showBus(BuildContext context, BusData data) {
    return _showModal(context, Text(data.number));
  }

  static Future<void> showBusStop(BuildContext context, BusStopData data) {
    return _showModal(context, Text(data.name));
  }
}