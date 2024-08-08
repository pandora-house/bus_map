import 'dart:async';

import 'package:bus_map/map/models/bus_data.dart';
import 'package:bus_map/map/models/bus_stop_data.dart';
import 'package:bus_map/map/widgets/modals.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'controllers/locator_controller.dart';
import 'controllers/markers_controller.dart';
import 'models/point_meta.dart';
import 'widgets/user_locator_button.dart';

class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.busStream,
    required this.stops,
  });

  final Stream<List<PointMeta<BusData>>> busStream;
  final List<PointMeta<BusStopData>> stops;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  YandexMapController? _mapController;

  final _markersController = MarkersController();

  StreamSubscription<Position>? _userPositionSub;
  Position? _currentUserPos;

  static const _initCameraZoom = 13.0;
  static const _maxCameraZoom = 25.0;

  var _buses = <PointMeta<BusData>>[];
  late final StreamSubscription<List<PointMeta<BusData>>> _busesSub;

  PointMeta<BusData>? _busTap;

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
      widget.stops,
      onTap: _onStopTap,
    );
    _busesSub = widget.busStream.listen((buses) async {
      _buses = buses;
      await _markersController.buildBus(
        _buses,
        onTap: _onBusTap,
      );

      await _updateBusCameraPos();
    });
  }

  @override
  void dispose() {
    _busesSub.cancel();
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

  Future<void> _updateBusCameraPos() async {
    if (_busTap == null) return;
    await Future.delayed(const Duration(milliseconds: 200));

    final meta = _buses.firstWhereOrNull((e) => e.id == _busTap!.id);
    if (meta == null) return;

    await _mapController?.moveCamera(
      animation: const MapAnimation(type: MapAnimationType.linear, duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: _maxCameraZoom,
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
    final currCameraPos = await _mapController?.getCameraPosition();
    double bearing = Geolocator.bearingBetween(
      currCameraPos!.target.latitude,
      currCameraPos.target.longitude,
      meta.point.latitude,
      meta.point.longitude,
    );

    // анимация кластера сделана нативно промаргивание не избежно,
    // по-этому сначала перемещаем камер и итолько потом обновляем маркеры
    // https://github.com/Unact/yandex_mapkit/issues/175
    await _mapController?.moveCamera(
      animation: bearing.abs() < 0.005 ? null : const MapAnimation(duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: _maxCameraZoom,
        ),
      ),
    );

    await _markersController.showStopPressed(meta);

    if (!mounted) return;
    final data = meta.data as BusStopData;
    Modals.showBusStop(context, data).then((_) {
      _markersController.hideStopPressed(meta);
    });
  }

  Future<void> _onBusTap(PointMeta meta) async {
    _busTap = meta as PointMeta<BusData>;
    Modals.showBus(context, meta.data).then((_) {
      _busTap = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await _mapController?.moveCamera(
      animation: const MapAnimation(duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: 25,
        ),
      ),
    );
  }

  void _onScale(CameraPosition pos) {
    if (pos.zoom > 13 && _markersController.busScale != 2) {
      _markersController.buildBus(_buses, onTap: _onBusTap, scale: 2);
    } else if (pos.zoom <= 13 &&
        pos.zoom > 12 &&
        _markersController.busScale != 1.5) {
      _markersController.buildBus(_buses, onTap: _onBusTap, scale: 1.5);
    } else if (pos.zoom <= 12 &&
        pos.zoom > 11 &&
        _markersController.busScale != 1) {
      _markersController.buildBus(_buses, onTap: _onBusTap, scale: 1);
    } else if (pos.zoom <= 11 && _markersController.busScale != 0.7) {
      _markersController.buildBus(_buses, onTap: _onBusTap, scale: 0.7);
    }

    if (pos.zoom > 13 && _markersController.stopScale != 2) {
      _markersController.buildBusStops(widget.stops,
          onTap: _onStopTap, scale: 2);
    } else if (pos.zoom <= 13 &&
        pos.zoom > 12 &&
        _markersController.stopScale != 1.5) {
      _markersController.buildBusStops(widget.stops,
          onTap: _onStopTap, scale: 1.5);
    } else if (pos.zoom <= 12 &&
        pos.zoom > 11 &&
        _markersController.stopScale != 1) {
      _markersController.buildBusStops(widget.stops,
          onTap: _onStopTap, scale: 1);
    } else if (pos.zoom <= 11 && _markersController.stopScale != 0.5) {
      _markersController.buildBusStops(widget.stops,
          onTap: _onStopTap, scale: 0.5);
    }
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
                  if (reason == CameraUpdateReason.application) {
                    return;
                  }
                  _onScale(pos);
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
