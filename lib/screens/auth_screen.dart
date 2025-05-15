import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void toggleForm() {
    setState(() {
      isSignUp = !isSignUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignUp ? 'Criar Conta' : 'Bem Vindo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.deepBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text(isSignUp ? 'Cadastre-se' : 'Entre em sua conta'),
            ),
            TextButton(
              onPressed: toggleForm,
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlueAccent, // Change this to your desired color
              ),
              child: Text(isSignUp
                  ? 'Já possui uma conta? Entre em sua conta'
                  : 'Não possui uma? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}
