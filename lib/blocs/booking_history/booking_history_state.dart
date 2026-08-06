part of 'booking_history_bloc.dart';

enum BookingHistoryStatus { initial, loading, success, failure }

enum BookingPaymentStatus { idle, loading, success, failure }

class BookingHistoryState extends Equatable {
  const BookingHistoryState({
    this.status = BookingHistoryStatus.initial,
    this.paymentStatus = BookingPaymentStatus.idle,
    this.bookings = const [],
    this.email,
    this.payingBookingId,
    this.message,
  });

  final BookingHistoryStatus status;
  final BookingPaymentStatus paymentStatus;
  final List<Booking> bookings;
  final String? email;
  final int? payingBookingId;
  final String? message;

  bool get isLoading => status == BookingHistoryStatus.loading;

  BookingHistoryState copyWith({
    BookingHistoryStatus? status,
    BookingPaymentStatus? paymentStatus,
    List<Booking>? bookings,
    String? email,
    int? payingBookingId,
    String? message,
    bool clearMessage = false,
  }) {
    return BookingHistoryState(
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookings: bookings ?? this.bookings,
      email: email ?? this.email,
      payingBookingId: payingBookingId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        paymentStatus,
        bookings,
        email,
        payingBookingId,
        message,
      ];
}
