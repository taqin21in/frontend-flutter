import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/booking.dart';
import '../../services/api_client.dart';

part 'booking_history_event.dart';
part 'booking_history_state.dart';

class BookingHistoryBloc
    extends Bloc<BookingHistoryEvent, BookingHistoryState> {
  BookingHistoryBloc(this._apiClient) : super(const BookingHistoryState()) {
    on<BookingHistoryRequested>(_onRequested);
    on<BookingPaymentSubmitted>(_onPaymentSubmitted);
  }

  final ApiClient _apiClient;

  Future<void> _onRequested(
    BookingHistoryRequested event,
    Emitter<BookingHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingHistoryStatus.loading,
        paymentStatus: BookingPaymentStatus.idle,
        email: event.email,
        payingBookingId: null,
        clearMessage: true,
      ),
    );

    try {
      final bookings = await _apiClient.fetchBookings(event.email);
      emit(
        state.copyWith(
          status: BookingHistoryStatus.success,
          bookings: bookings,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: BookingHistoryStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingHistoryStatus.failure,
          message: 'Riwayat booking belum bisa dimuat',
        ),
      );
    }
  }

  Future<void> _onPaymentSubmitted(
    BookingPaymentSubmitted event,
    Emitter<BookingHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        paymentStatus: BookingPaymentStatus.loading,
        payingBookingId: event.bookingId,
        clearMessage: true,
      ),
    );

    try {
      await _apiClient.payBooking(event.bookingId, 'TRANSFER');
      final bookings = await _apiClient.fetchBookings(event.email);
      emit(
        state.copyWith(
          status: BookingHistoryStatus.success,
          paymentStatus: BookingPaymentStatus.success,
          bookings: bookings,
          payingBookingId: null,
          message: 'Pembayaran berhasil dikonfirmasi',
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          paymentStatus: BookingPaymentStatus.failure,
          payingBookingId: null,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          paymentStatus: BookingPaymentStatus.failure,
          payingBookingId: null,
          message: 'Pembayaran gagal diproses',
        ),
      );
    }
  }
}
