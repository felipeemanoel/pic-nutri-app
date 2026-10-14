import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/profile_repository.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(current: _current.text, newPassword: _new.text);
      if (!mounted) return;
      showMessage(
        context,
        'Senha alterada. Os outros aparelhos foram desconectados.',
      );
      context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      showFailure(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alterar senha')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _current,
            decoration: InputDecoration(
              labelText: 'Senha atual',
              errorText: fieldError(_error, 'current_password'),
            ),
            obscureText: true,
            validator: (v) => Validators.required(v, 'Senha atual'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _new,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              helperText: 'Pelo menos 8 caracteres',
              errorText: fieldError(_error, 'password'),
            ),
            obscureText: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 20),
          LoadingButton(label: 'Salvar', loading: _loading, onPressed: _submit),
        ],
      ),
    ),
  );
}
