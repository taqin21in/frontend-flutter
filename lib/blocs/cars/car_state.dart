part of 'car_bloc.dart';

enum CarStatus { initial, loading, success, failure }

class CarState extends Equatable {
  const CarState({
    this.status = CarStatus.initial,
    this.cars = const [],
    this.onlyAvailable = true,
    this.message,
  });

  final CarStatus status;
  final List<Car> cars;
  final bool onlyAvailable;
  final String? message;

  bool get isLoading => status == CarStatus.loading;

  CarState copyWith({
    CarStatus? status,
    List<Car>? cars,
    bool? onlyAvailable,
    String? message,
    bool clearMessage = false,
  }) {
    return CarState(
      status: status ?? this.status,
      cars: cars ?? this.cars,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, cars, onlyAvailable, message];
}
