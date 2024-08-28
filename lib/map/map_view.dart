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

  late final _markersController = MarkersController(
    locatorController: LocatorController(),
    onStopMarkerTap: (point) {
      _onStopTap(meta: point, mapController: _mapController!, context: context);
    },
    onBusMarkerTap: (point) {
      _onBusTap(meta: point, mapController: _mapController!, context: context);
    },
  );

  static const _initCameraZoom = 13.0;
  static const _maxCameraZoom = 25.0;

  var _buses = <PointMeta<BusData>>[];
  late final StreamSubscription<List<PointMeta<BusData>>> _busesSub;

  PointMeta<BusData>? _busTap;

  @override
  void initState() {
    super.initState();
    _markersController.buildBusStops(widget.stops);
    _busesSub = widget.busStream.listen((buses) async {
      _buses = buses;
      await _markersController.buildBus(_buses);

      await _updateBusCameraPos();
    });
  }

  @override
  void dispose() {
    _busesSub.cancel();
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

  Future<void> _onStopTap({
    required PointMeta meta,
    required YandexMapController mapController,
    required BuildContext context,
  }) async {
    final currCameraPos = await mapController.getCameraPosition();
    double bearing = Geolocator.bearingBetween(
      currCameraPos.target.latitude,
      currCameraPos.target.longitude,
      meta.point.latitude,
      meta.point.longitude,
    );

    // анимация кластера сделана нативно промаргивание не избежно,
    // по-этому сначала перемещаем камер и итолько потом обновляем маркеры
    // https://github.com/Unact/yandex_mapkit/issues/175
    await mapController.moveCamera(
      animation: bearing.abs() < 0.005 ? null : const MapAnimation(duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: meta.point,
          zoom: _maxCameraZoom,
        ),
      ),
    );

    await _markersController.showStopPressed(meta);

    if (!context.mounted) return;
    final data = meta.data as BusStopData;
    Modals.showBusStop(context, data).then((_) {
      _markersController.hideStopPressed(meta);
    });
  }

  Future<void> _onBusTap({
    required PointMeta meta,
    required YandexMapController mapController,
    required BuildContext context,
  }) async {
    _busTap = meta as PointMeta<BusData>;
    Modals.showBus(context, meta.data).then((_) {
      _busTap = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await mapController.moveCamera(
      animation: const MapAnimation(duration: 1),
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
                  _markersController.onScale(
                    pos: pos,
                    reason: reason,
                    stops: widget.stops,
                    buses: _buses,
                  );
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
            onTap: () {
              _markersController.onUserLocatorTap(_mapController!);
            },
          ),
        ],
      ),
    );
  }
}
