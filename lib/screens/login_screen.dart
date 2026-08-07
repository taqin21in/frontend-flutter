import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/cars/car_bloc.dart';
import '../services/api_client.dart';
import 'car_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'mtq');
  final _emailController = TextEditingController(text: 'muttaqin@example.com');
  final _phoneController = TextEditingController(text: '08xxxx');
  final _passwordController = TextEditingController(text: 'customer123');

  bool _registerMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_registerMode) {
      context.read<AuthBloc>().add(
            AuthRegisterSubmitted(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _openCarList(AuthState state) {
    final session = state.session;
    if (session == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              CarBloc(context.read<ApiClient>())..add(const CarsRequested()),
          child: CarListScreen(session: session),
        ),
      ),
    );
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _openCarList(state);
        }

        if (state.status == AuthStatus.failure) {
          _showMessage(state.message);
        }
      },
      builder: (context, state) {
        final loading = state.isLoading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.car_rental,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Sewa Mobil',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk untuk memilih mobil dan mengajukan penyewaan.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.login),
                              label: Text('Login'),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.person_add),
                              label: Text('Daftar'),
                            ),
                          ],
                          selected: {_registerMode},
                          onSelectionChanged: loading
                              ? null
                              : (value) =>
                                  setState(() => _registerMode = value.first),
                        ),
                        const SizedBox(height: 18),
                        if (_registerMode) ...[
                          TextFormField(
                            controller: _nameController,
                            enabled: !loading,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nama wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            enabled: !loading,
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nomor HP wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Email tidak valid'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !loading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'Minimal 6 karakter'
                                  : null,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: loading ? null : _submit,
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _registerMode
                                      ? Icons.person_add
                                      : Icons.login,
                                ),
                          label: Text(_registerMode ? 'Buat Akun' : 'Masuk'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
