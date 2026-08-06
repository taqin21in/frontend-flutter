part of 'booking_form_bloc.dart';

enum BookingFormStatus { initial, submitting, success, failure }

class BookingFormState extends Equatable {
  const BookingFormState({
    required this.startDate,
    required this.endDate,
    this.status = BookingFormStatus.initial,
    this.createdBooking,
    this.message,
  });

  factory BookingFormState.initial() {
    final startDate = DateTime.now().add(const Duration(days: 1));
    return BookingFormState(
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 2)),
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final BookingFormStatus status;
  final Booking? createdBooking;
  final String? message;

  int get days => endDate.difference(startDate).inDays + 1;
  bool get isSubmitting => status == BookingFormStatus.submitting;

  BookingFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    BookingFormStatus? status,
    Booking? createdBooking,
    String? message,
    bool clearCreatedBooking = false,
    bool clearMessage = false,
  }) {
    return BookingFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdBooking:
          clearCreatedBooking ? null : createdBooking ?? this.createdBooking,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        status,
        createdBooking,
        message,
      ];
}
