part of 'booking_form_bloc.dart';

sealed class BookingFormEvent extends Equatable {
  const BookingFormEvent();

  @override
  List<Object?> get props => [];
}

class BookingStartDateChanged extends BookingFormEvent {
  const BookingStartDateChanged(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class BookingEndDateChanged extends BookingFormEvent {
  const BookingEndDateChanged(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class BookingSubmitted extends BookingFormEvent {
  const BookingSubmitted({
    required this.userId,
    required this.carId,
    required this.pickupLocation,
    required this.returnLocation,
  });

  final int userId;
  final int carId;
  final String pickupLocation;
  final String returnLocation;

  @override
  List<Object?> get props => [userId, carId, pickupLocation, returnLocation];
}
