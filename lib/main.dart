import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SewaMobilApp());
}

class SewaMobilApp extends StatelessWidget {
  const SewaMobilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: BlocProvider(
        create: (_) => AuthBloc(apiClient),
        child: MaterialApp(
          title: 'Sewa Mobil',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
