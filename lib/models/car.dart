class Car {
  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.year,
    required this.imageUrl,
    required this.seats,
    required this.transmission,
    required this.pricePerDay,
    required this.status,
    required this.description,
  });

  final int id;
  final String brand;
  final String model;
  final String plateNumber;
  final int year;
  final String imageUrl;
  final int seats;
  final String transmission;
  final double pricePerDay;
  final String status;
  final String description;

  String get title => '$brand $model';
  bool get isAvailable => status == 'AVAILABLE';

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      seats: json['seats'] as int? ?? 0,
      transmission: json['transmission'] as String? ?? '',
      pricePerDay: _toDouble(json['pricePerDay']),
      status: json['status'] as String? ?? 'AVAILABLE',
      description: json['description'] as String? ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
