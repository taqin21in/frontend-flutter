import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/car.dart';
import '../../services/api_client.dart';

part 'car_event.dart';
part 'car_state.dart';

class CarBloc extends Bloc<CarEvent, CarState> {
  CarBloc(this._apiClient) : super(const CarState()) {
    on<CarsRequested>(_onCarsRequested);
    on<CarAvailabilityFilterChanged>(_onAvailabilityFilterChanged);
  }

  final ApiClient _apiClient;

  Future<void> _onCarsRequested(
    CarsRequested event,
    Emitter<CarState> emit,
  ) async {
    emit(state.copyWith(status: CarStatus.loading, clearMessage: true));

    try {
      final cars = await _apiClient.fetchCars(
        onlyAvailable: state.onlyAvailable,
      );
      emit(state.copyWith(status: CarStatus.success, cars: cars));
    } on ApiException catch (error) {
      emit(state.copyWith(status: CarStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: CarStatus.failure,
          message: 'Data mobil belum bisa dimuat',
        ),
      );
    }
  }

  Future<void> _onAvailabilityFilterChanged(
    CarAvailabilityFilterChanged event,
    Emitter<CarState> emit,
  ) async {
    emit(state.copyWith(onlyAvailable: event.onlyAvailable));
    add(const CarsRequested());
  }
}
