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
          margin: const EdgeInsets.only(top: 3),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 0),
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 20.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 16),
                width: 37,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x40003387),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }

  static Future<void> showBus(BuildContext context, BusData data) {
    final child = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.number),
                  Text(data.route),
                ],
              ),
            ),
            const _CloseButton(),
          ],
        ),
        const Divider(),
      ],
    );
    return _showModal(context, child);
  }

  static Future<void> showBusStop(BuildContext context, BusStopData data) {
    final child = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name),
                  Text(data.street),
                ],
              ),
            ),
            const _CloseButton(),
          ],
        ),
        const Divider(),
      ],
    );
    return _showModal(context, child);
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Navigator.of(context).pop,
      child: Image.asset(
        'assets/close_modal_icon.png',
        height: 24,
        width: 24,
      ),
    );
  }
}
