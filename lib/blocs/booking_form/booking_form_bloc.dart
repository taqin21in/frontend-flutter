import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/booking.dart';
import '../../services/api_client.dart';

part 'booking_form_event.dart';
part 'booking_form_state.dart';

class BookingFormBloc extends Bloc<BookingFormEvent, BookingFormState> {
  BookingFormBloc(this._apiClient) : super(BookingFormState.initial()) {
    on<BookingStartDateChanged>(_onStartDateChanged);
    on<BookingEndDateChanged>(_onEndDateChanged);
    on<BookingSubmitted>(_onSubmitted);
  }

  final ApiClient _apiClient;

  void _onStartDateChanged(
    BookingStartDateChanged event,
    Emitter<BookingFormState> emit,
  ) {
    final endDate = state.endDate.isBefore(event.startDate)
        ? event.startDate
        : state.endDate;

    emit(
      state.copyWith(
        startDate: event.startDate,
        endDate: endDate,
        status: BookingFormStatus.initial,
        clearMessage: true,
        clearCreatedBooking: true,
      ),
    );
  }

  void _onEndDateChanged(
    BookingEndDateChanged event,
    Emitter<BookingFormState> emit,
  ) {
    final endDate = event.endDate.isBefore(state.startDate)
        ? state.startDate
        : event.endDate;

    emit(
      state.copyWith(
        endDate: endDate,
        status: BookingFormStatus.initial,
        clearMessage: true,
        clearCreatedBooking: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    BookingSubmitted event,
    Emitter<BookingFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingFormStatus.submitting,
        clearMessage: true,
        clearCreatedBooking: true,
      ),
    );

    try {
      final booking = await _apiClient.createBooking(
        userId: event.userId,
        carId: event.carId,
        startDate: state.startDate,
        endDate: state.endDate,
        pickupLocation: event.pickupLocation,
        returnLocation: event.returnLocation,
      );

      emit(
        state.copyWith(
          status: BookingFormStatus.success,
          createdBooking: booking,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: BookingFormStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingFormStatus.failure,
          message: 'Tidak dapat membuat booking',
        ),
      );
    }
  }
}
