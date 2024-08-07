import 'dart:async';

import 'package:bus_map/map/models/bus_data.dart';
import 'package:bus_map/map/models/bus_stop_data.dart';
import 'package:bus_map/map/widgets/modals.dart';
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

  static const _initCameraZoom = 13.0;

  final _buses = <PointMeta<BusData>>[
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
    const PointMeta<BusData>(
      id: 'bus-109',
      point: Point(
        latitude: 59.122672,
        longitude: 37.915443,
      ),
      text: '109',
      data: BusData(
        route: 'Азотный комплекс - ЗШК',
        number: '109',
      ),
    ),
  ];

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
        const PointMeta<BusStopData>(
          id: 'stop-102',
          point: Point(
            latitude: 59.099550,
            longitude: 37.916079,
          ),
          text: '102',
          data: BusStopData(
            shortName: '102',
            name: '102-микрорайон',
            street: 'Сталинградская, 19',
          ),
        ),
      ],
      onTap: _onStopTap,
    );
    _markersController.buildBus(
      _buses,
      onTap: _onBusTap,
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
          zoom: _initCameraZoom,
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

  Future<void> _onStopTap(PointMeta meta) async {
    _markersController.showStopPressed(meta);
    final data = meta.data as BusStopData;

    Modals.showBusStop(context).then((_) {
      _markersController.hideStopPressed(meta);
    });

    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: 25,
        ),
      ),
    );
  }

  Future<void> _onBusTap(PointMeta meta) async {
    // _markersController.showStopPressed(meta);
    final data = meta.data as BusData;

    Modals.showBus(context).then((_) {
      _markersController.hideStopPressed(meta);
    });

    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: 25,
        ),
      ),
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
                onCameraPositionChanged: (pos, reason, _) {
                  if (pos.zoom > 13 && _markersController.busScale != 2) {
                    _markersController.buildBus(
                      _buses,
                      onTap: _onBusTap,
                      scale: 2,
                    );
                  } else if (pos.zoom <= 13 &&
                      pos.zoom > 12 &&
                      _markersController.busScale != 1.5) {
                    _markersController.buildBus(
                      _buses,
                      onTap: _onBusTap,
                      scale: 1.5,
                    );
                  } else if (pos.zoom <= 12 &&
                      pos.zoom > 11 &&
                      _markersController.busScale != 1) {
                    _markersController.buildBus(
                      _buses,
                      onTap: _onBusTap,
                      scale: 1,
                    );
                  } else if (pos.zoom <= 11 &&
                      _markersController.busScale != 0.7) {
                    _markersController.buildBus(
                      _buses,
                      onTap: _onBusTap,
                      scale: 0.7,
                    );
                  }
                },
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
