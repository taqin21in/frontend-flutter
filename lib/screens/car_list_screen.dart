import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/booking_history/booking_history_bloc.dart';
import '../blocs/cars/car_bloc.dart';
import '../models/auth_session.dart';
import '../services/api_client.dart';
import '../widgets/car_card.dart';
import 'booking_history_screen.dart';
import 'car_detail_screen.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key, required this.session});

  final AuthSession session;

  Future<void> _reload(BuildContext context) async {
    context.read<CarBloc>().add(const CarsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mobil'),
        actions: [
          IconButton(
            tooltip: 'Riwayat',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => BookingHistoryBloc(context.read<ApiClient>())
                      ..add(BookingHistoryRequested(session.email)),
                    child: BookingHistoryScreen(session: session),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: BlocBuilder<CarBloc, CarState>(
        builder: (context, state) {
          if (state.status == CarStatus.loading && state.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CarStatus.failure && state.cars.isEmpty) {
            return _ErrorState(onRetry: () => _reload(context));
          }

          return RefreshIndicator(
            onRefresh: () => _reload(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _Header(
                  name: session.fullName,
                  onlyAvailable: state.onlyAvailable,
                  onChanged: (value) {
                    context.read<CarBloc>().add(
                          CarAvailabilityFilterChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 16),
                if (state.cars.isEmpty)
                  const _EmptyState()
                else
                  ...state.cars.map(
                    (car) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CarCard(
                        car: car,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CarDetailScreen(session: session, car: car),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.onlyAvailable,
    required this.onChanged,
  });

  final String name;
  final bool onlyAvailable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $name',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Cari mobil yang siap dipakai untuk perjalanan berikutnya.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.check_circle_outline),
              label: Text('Tersedia'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.apps),
              label: Text('Semua'),
            ),
          ],
          selected: {onlyAvailable},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42),
            const SizedBox(height: 12),
            const Text('Data mobil belum bisa dimuat.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: Text('Belum ada mobil tersedia.')),
    );
  }
}
