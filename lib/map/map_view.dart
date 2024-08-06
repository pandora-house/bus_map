import 'dart:async';

import 'package:bus_map/map/models/bus_data.dart';
import 'package:bus_map/map/models/bus_stop_data.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'controllers/locator_controller.dart';
import 'controllers/map_markers_controller.dart';
import 'models/point_meta.dart';
import 'widgets/user_locator_button.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  YandexMapController? _mapController;

  final _markersController = MapMarkersController();

  StreamSubscription<Position>? _userPositionSub;
  Position? _currentUserPos;

  @override
  void initState() {
    super.initState();
    LocatorController().getPositionUser().then((value) {
      _userPositionSub = value.listen((pos) {
        _currentUserPos = pos;
        _markersController.buildUser(Point(
          latitude: pos.latitude,
          longitude: pos.longitude,
        ));
      });
    });
    _markersController.buildBusStops(
      [
        const PointMeta<BusStopData>(
          id: 'stop-100',
          point: Point(
            latitude: 59.139550,
            longitude: 37.926079,
          ),
          text: '100',
          data: BusStopData(
            shortName: '100',
            name: '100-микрорайон',
            street: 'Ленинградская, 19',
          ),
        ),
        const PointMeta<BusStopData>(
          id: 'stop-101',
          point: Point(
            latitude: 59.139550,
            longitude: 37.906079,
          ),
          text: '101',
          data: BusStopData(
            shortName: '101',
            name: '101-микрорайон',
            street: 'Сталинградская, 19',
          ),
        ),
      ],
      onTap: _onStopTap,
    );
    _markersController.buildBus(
      [
        const PointMeta<BusData>(
          id: 'bus-409',
          point: Point(
            latitude: 59.122672,
            longitude: 37.913443,
          ),
          text: '409',
          data: BusData(
            route: 'Азотный комплекс - ЗШК',
            number: '409',
          ),
        ),
      ],
      onTap: (value) {
        final data = value.data as BusData;
        _showModal('Автобус ${value.text}');
      },
    );
  }

  @override
  void dispose() {
    _userPositionSub?.cancel();
    _markersController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<bool> _initCameraPos(YandexMapController controller) {
    // Череповец
    return controller.moveCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: Point(
            latitude: 59.122672,
            longitude: 37.903443,
          ),
          zoom: 13,
        ),
      ),
    );
  }

  Future<void> _onUserLocatorTap() async {
    _currentUserPos ??= await LocatorController().getLastKnownPosition();
    if (_currentUserPos == null) {
      return;
    }
    _markersController.buildUser(Point(
      latitude: _currentUserPos!.latitude,
      longitude: _currentUserPos!.longitude,
    ));

    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: _currentUserPos!.latitude,
            longitude: _currentUserPos!.longitude,
          ),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _onStopTap(PointMeta value) async {
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: value.point,
          zoom: 20,
        ),
      ),
    );

    _markersController.buildStopPressed(value);
    final data = value.data as BusStopData;
    _showModal('Остановка ${value.text}').then((_) {
      //todo hide icon on close
    });
  }

  Future<void> _showModal(String text) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: _markersController.mapObjects,
            builder: (context, objects, _) {
              return YandexMap(
                mapObjects: objects,
                onMapCreated: (controller) async {
                  _mapController = controller;

                  //https://github.com/Unact/yandex_mapkit/issues/245
                  final success = await _initCameraPos(controller);

                  if (!success) {
                    _initCameraPos(controller);
                  }
                },
              );
            },
          ),
          UserLocatorButton(
            onTap: _onUserLocatorTap,
          ),
        ],
      ),
    );
  }
}
