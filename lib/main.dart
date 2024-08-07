import 'dart:async';

import 'package:bus_map/map/map_view.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'map/models/bus_data.dart';
import 'map/models/bus_stop_data.dart';
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
          stops: [
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
          busStream: Stream.periodic(
            const Duration(milliseconds: 3000),
            (value) {
              return <PointMeta<BusData>>[
                PointMeta<BusData>(
                  id: 'bus-409',
                  point: Point(
                    latitude: 59.122672 + (value * 1.0000),
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
