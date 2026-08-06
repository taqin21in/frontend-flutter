import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/booking_form/booking_form_bloc.dart';
import '../models/auth_session.dart';
import '../models/car.dart';
import '../services/api_client.dart';
import 'booking_form_screen.dart';

class CarDetailScreen extends StatelessWidget {
  const CarDetailScreen({super.key, required this.session, required this.car});

  final AuthSession session;
  final Car car;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(car.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: car.isAvailable
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) =>
                              BookingFormBloc(context.read<ApiClient>()),
                          child: BookingFormScreen(session: session, car: car),
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Sewa Sekarang'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: car.imageUrl.isEmpty
                ? const _ImageFallback()
                : Image.network(
                    car.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImageFallback(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text('${car.plateNumber} • ${car.year}'),
                        ],
                      ),
                    ),
                    Text(
                      '${currency.format(car.pricePerDay)}/hari',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Spec(icon: Icons.event_seat, label: '${car.seats} kursi'),
                    _Spec(icon: Icons.settings, label: car.transmission),
                    _Spec(icon: Icons.verified, label: car.status),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Deskripsi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  car.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.directions_car_filled,
        size: 72,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
