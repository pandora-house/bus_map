import 'dart:async';

import 'package:bus_map/map/map_view.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'map/models/bus_data.dart';
import 'map/models/point_meta.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: MapView(
          busStream: Stream.periodic(
            const Duration(milliseconds: 3000),
            (value) {
              return <PointMeta<BusData>>[
                PointMeta<BusData>(
                  id: 'bus-409',
                  point: Point(
                    latitude: 59.122672 + (value * 0.0001),
                    longitude: 37.913443,
                  ),
                  text: '409',
                  data: BusData(
                    route: 'Азотный комплекс - ЗШК',
                    number: '409',
                  ),
                ),
                PointMeta<BusData>(
                  id: 'bus-109',
                  point: Point(
                    latitude: 59.122672,
                    longitude: 37.915443 + (value * 0.0001),
                  ),
                  text: '109',
                  data: BusData(
                    route: 'Азотный комплекс - ЗШК',
                    number: '109',
                  ),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
