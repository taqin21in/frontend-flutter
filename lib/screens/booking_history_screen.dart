import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/booking_history/booking_history_bloc.dart';
import '../models/auth_session.dart';
import '../models/booking.dart';
import '../widgets/booking_status_chip.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key, required this.session});

  final AuthSession session;

  Future<void> _reload(BuildContext context) async {
    context.read<BookingHistoryBloc>().add(
          BookingHistoryRequested(session.email),
        );
  }

  void _pay(BuildContext context, Booking booking) {
    context.read<BookingHistoryBloc>().add(
          BookingPaymentSubmitted(bookingId: booking.id, email: session.email),
        );
  }

  void _showMessage(BuildContext context, String? message) {
    if (message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingHistoryBloc, BookingHistoryState>(
      listenWhen: (previous, current) =>
          previous.paymentStatus != current.paymentStatus,
      listener: (context, state) {
        if (state.paymentStatus == BookingPaymentStatus.success ||
            state.paymentStatus == BookingPaymentStatus.failure) {
          _showMessage(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Riwayat Booking')),
          body: RefreshIndicator(
            onRefresh: () => _reload(context),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookingHistoryState state) {
    if (state.status == BookingHistoryStatus.loading &&
        state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == BookingHistoryStatus.failure &&
        state.bookings.isEmpty) {
      return _ErrorState(onRetry: () => _reload(context));
    }

    if (state.bookings.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = state.bookings[index];
        final paying = state.payingBookingId == booking.id;

        return _BookingTile(
          booking: booking,
          paying: paying,
          onPay: booking.status == 'PENDING' && !paying
              ? () => _pay(context, booking)
              : null,
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.paying,
    required this.onPay,
  });

  final Booking booking;
  final bool paying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.car.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
            ),
            const SizedBox(height: 4),
            Text('Ambil: ${booking.pickupLocation}'),
            Text('Kembali: ${booking.returnLocation}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    currency.format(booking.totalPrice),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (onPay != null || paying)
                  FilledButton.icon(
                    onPressed: onPay,
                    icon: paying
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: const Text('Bayar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Muat Ulang'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.receipt_long_outlined, size: 54),
        SizedBox(height: 12),
        Center(child: Text('Belum ada booking.')),
      ],
    );
  }
}
