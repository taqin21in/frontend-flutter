import 'car.dart';

class Booking {
  const Booking({
    required this.id,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.returnLocation,
    required this.totalPrice,
    required this.status,
  });

  final int id;
  final Car car;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String returnLocation;
  final double totalPrice;
  final String status;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      car: Car.fromJson(json['car'] as Map<String, dynamic>),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      pickupLocation: json['pickupLocation'] as String? ?? '',
      returnLocation: json['returnLocation'] as String? ?? '',
      totalPrice: _toDouble(json['totalPrice']),
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
