import 'package:yandex_mapkit/yandex_mapkit.dart';

class PointMeta<T> {
  const PointMeta({
    required this.id,
    required this.point,
    required this.text,
    required this.data,
  });

  final String id;
  final Point point;
  final String text;
  final T data;
}