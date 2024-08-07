import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/point_meta.dart';

class MapMarkersController {
  final _mapObjects = ValueNotifier<List<MapObject<dynamic>>>([]);

  ValueNotifier<List<MapObject<dynamic>>> get mapObjects => _mapObjects;

  final _userMarkerId = const MapObjectId('user_placemark');
  final _busStopPressedMarkerId =
      const MapObjectId('bus_stop_pressed_placemark');
  final _busStopClusterMarkerId = const MapObjectId('stop-cluster');

  var _busObjects = <PlacemarkMapObject>[];
  var _busStopObjects = <PlacemarkMapObject>[];
  late PlacemarkMapObject _userObject = PlacemarkMapObject(
    mapId: _userMarkerId,
    point: const Point(latitude: 0, longitude: 0),
  );
  late PlacemarkMapObject _busStopRemovedObject = PlacemarkMapObject(
    mapId: _userMarkerId,
    point: const Point(latitude: 0, longitude: 0),
  );

  double _busScale = 1.5;
  double _stopScale = 1.5;

  double get busScale => _busScale;

  double get stopScale => _stopScale;

  void _updateMarkers() {
    _mapObjects.value = [
      _stopsCluster(_busStopObjects),
      _userObject,
      ..._busObjects,
    ];
  }

  ClusterizedPlacemarkCollection _stopsCluster(List<PlacemarkMapObject> marks) {
    return ClusterizedPlacemarkCollection(
      mapId: _busStopClusterMarkerId,
      placemarks: marks,
      radius: 12,
      minZoom: 20,
      consumeTapEvents: true,
    );
  }

  void buildUser(Point point) {
    _userObject = PlacemarkMapObject(
      mapId: _userMarkerId,
      point: point,
      opacity: 0.8,
      zIndex: 3,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image:
              BitmapDescriptor.fromAssetImage('assets/user_location_icon.png'),
          scale: 2,
        ),
      ),
    );
    _updateMarkers();
  }

  Future<void> buildBusStops(List<PointMeta> points,
      {Function(PointMeta)? onTap, double? scale}) async {
    if (scale != null) {
      _stopScale = scale;
    }

    final image = await _loadUiImage('assets/bus_stop_icon.png');
    _busStopObjects = <PlacemarkMapObject>[];
    for (final p in points) {
      final imgBytes = await _buildBusStopAppearance(p.text, image, _stopScale);
      final marker = PlacemarkMapObject(
        mapId: MapObjectId(p.id),
        point: p.point,
        opacity: 1,
        zIndex: 1,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            anchor: const Offset(0.25, 0.5),
            image: BitmapDescriptor.fromBytes(imgBytes),
            scale: _stopScale,
          ),
        ),
        onTap: (obj, point) {
          onTap?.call(p);
        },
      );
      _busStopObjects.add(marker);
    }

    _updateMarkers();
  }

  Future<void> showStopPressed(PointMeta point) async {
    _busStopRemovedObject =
        _busStopObjects.firstWhere((e) => e.mapId == MapObjectId(point.id));
    _busStopObjects = _busStopObjects
      ..removeWhere((e) => e.mapId == MapObjectId(point.id));
    _busStopObjects = _busStopObjects
      ..removeWhere((e) => e.mapId == _busStopPressedMarkerId);
    final marker = PlacemarkMapObject(
      mapId: _busStopPressedMarkerId,
      point: point.point,
      opacity: 1,
      zIndex: 1,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage(
              'assets/bus_stop_pressed_icon.png'),
          scale: 2,
          anchor: const Offset(0.40, 1.2),
        ),
      ),
    );
    _busStopObjects.add(marker);
    _updateMarkers();
  }

  Future<void> hideStopPressed(PointMeta point) async {
    _busStopObjects = _busStopObjects
      ..removeWhere((e) => e.mapId == _busStopPressedMarkerId);
    _busStopObjects.add(_busStopRemovedObject);
    _updateMarkers();
  }

  Future<void> buildBus(List<PointMeta> points,
      {Function(PointMeta)? onTap, double? scale}) async {
    if (scale != null) {
      _busScale = scale;
    }
    _busObjects = <PlacemarkMapObject>[];
    for (final p in points) {
      final imgBytes = await _buildBusAppearance(p.text);
      final marker = PlacemarkMapObject(
        mapId: MapObjectId(p.id),
        point: p.point,
        opacity: 1,
        consumeTapEvents: true,
        zIndex: 0 + (points.indexOf(p) * 0.1),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(imgBytes),
            scale: _busScale,
          ),
        ),
        onTap: (obj, point) {
          onTap?.call(p);
        },
      );
      _busObjects.add(marker);
    }
    _updateMarkers();
  }

  Future<Uint8List> _buildBusAppearance(String text) async {
    const radius = 25.0;
    const size = Size(90, 90);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    final circleOffset = Offset(
      size.height / 2,
      size.width / 2,
    );

    canvas.drawShadow(
      Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2 - 6),
            radius: radius,
          ),
        ),
      Colors.black,
      3,
      true,
    );

    canvas.drawCircle(circleOffset, radius, fillPaint);
    canvas.drawCircle(circleOffset, radius, strokePaint);

    textPainter.paint(canvas, textOffset);

    final image = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final pngBytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return pngBytes!.buffer.asUint8List();
  }

  Future<Uint8List> _buildBusStopAppearance(
      String text, ui.Image pic, double scale) async {
    const iconSize = 44.0;
    const gapIcon = 2.0;
    const textPadding = 4.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0x33707372)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final width = iconSize + gapIcon + textPadding * 2 + textPainter.width;
    final size = Size(width + 3, iconSize);

    final rectHeight = size.height - 10;
    final rectWidth = textPadding * 2 + textPainter.width;

    const textOffset = Offset(
      iconSize + gapIcon + textPadding,
      8,
    );

    if (scale >= 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            iconSize + gapIcon,
            0,
            rectWidth,
            rectHeight,
          ),
          const Radius.circular(4),
        ),
        fillPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            iconSize + gapIcon,
            0,
            rectWidth,
            rectHeight,
          ),
          const Radius.circular(4),
        ),
        strokePaint,
      );

      textPainter.paint(canvas, textOffset);
    }

    canvas.drawImage(
      pic,
      Offset.zero,
      Paint()..style = PaintingStyle.fill,
    );

    final image = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final pngBytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return pngBytes!.buffer.asUint8List();
  }

  static Future<ui.Image> _loadUiImage(String pic) async {
    final bytes = (await rootBundle.load(pic)).buffer.asUint8List();
    final img.Image image = img.decodeImage(bytes)!;
    final img.Image resized = img.copyResize(image, width: 44);
    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromList(
      img.encodePng(resized),
      (img) => completer.complete(img),
    );
    return completer.future;
  }

  void dispose() {
    _mapObjects.dispose();
  }
}
