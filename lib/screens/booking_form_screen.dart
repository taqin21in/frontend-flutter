import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/booking_form/booking_form_bloc.dart';
import '../models/auth_session.dart';
import '../models/car.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    required this.session,
    required this.car,
  });

  final AuthSession session;
  final Car car;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController(
    text: 'Kantor Sewa Mobil Jakarta',
  );
  final _returnController = TextEditingController(
    text: 'Kantor Sewa Mobil Jakarta',
  );

  @override
  void dispose() {
    _pickupController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final bloc = context.read<BookingFormBloc>();
    final state = bloc.state;
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? state.startDate : state.endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) {
      return;
    }

    bloc.add(
      start
          ? BookingStartDateChanged(selected)
          : BookingEndDateChanged(selected),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<BookingFormBloc>().add(
          BookingSubmitted(
            userId: widget.session.userId,
            carId: widget.car.id,
            pickupLocation: _pickupController.text.trim(),
            returnLocation: _returnController.text.trim(),
          ),
        );
  }

  Future<void> _showSuccess(BookingFormState state) async {
    final booking = state.createdBooking;
    if (booking == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Dibuat'),
        content: Text(
          'Kode booking #${booking.id} berstatus ${booking.status}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showMessage(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return BlocConsumer<BookingFormBloc, BookingFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BookingFormStatus.success) {
          _showSuccess(state);
        }

        if (state.status == BookingFormStatus.failure) {
          _showMessage(state.message);
        }
      },
      builder: (context, state) {
        final loading = state.isSubmitting;
        final total = widget.car.pricePerDay * state.days;

        return Scaffold(
          appBar: AppBar(title: const Text('Form Sewa')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_filled,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.car.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${currency.format(widget.car.pricePerDay)}/hari',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Mulai',
                        value: _formatDate(state.startDate),
                        onTap: loading ? null : () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'Selesai',
                        value: _formatDate(state.endDate),
                        onTap: loading ? null : () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pickupController,
                  enabled: !loading,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi ambil',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lokasi ambil wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _returnController,
                  enabled: !loading,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi kembali',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lokasi kembali wajib diisi'
                      : null,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total ${state.days} hari',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          currency.format(total),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Ajukan Booking'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
