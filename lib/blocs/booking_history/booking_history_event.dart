part of 'booking_history_bloc.dart';

sealed class BookingHistoryEvent extends Equatable {
  const BookingHistoryEvent();

  @override
  List<Object?> get props => [];
}

class BookingHistoryRequested extends BookingHistoryEvent {
  const BookingHistoryRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class BookingPaymentSubmitted extends BookingHistoryEvent {
  const BookingPaymentSubmitted({required this.bookingId, required this.email});

  final int bookingId;
  final String email;

  @override
  List<Object?> get props => [bookingId, email];
}
