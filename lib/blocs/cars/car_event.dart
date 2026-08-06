part of 'car_bloc.dart';

sealed class CarEvent extends Equatable {
  const CarEvent();

  @override
  List<Object?> get props => [];
}

class CarsRequested extends CarEvent {
  const CarsRequested();
}

class CarAvailabilityFilterChanged extends CarEvent {
  const CarAvailabilityFilterChanged(this.onlyAvailable);

  final bool onlyAvailable;

  @override
  List<Object?> get props => [onlyAvailable];
}
