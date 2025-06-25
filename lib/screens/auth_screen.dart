// ARQUIVO: lib/screens/auth_screen.dart (versão com Firebase)

import 'package:firebase_auth/firebase_auth.dart';
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
    return Scaffold( // Adicionado Scaffold para melhor estrutura e para usar o SnackBar
      body: Padding(
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
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 20),
              // AQUI ESTÁ A LÓGICA ADICIONADA:
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Por favor, preencha email e senha.'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }

                  try {
                    if (isSignUp) {
                      // Lógica de CADASTRO
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    } else {
                      // Lógica de LOGIN
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    }
                    // Se chegar aqui, o login/cadastro deu certo.
                    // O StreamBuilder no main.dart vai detectar a mudança e
                    // navegar para a HomeScreen automaticamente.

                  } on FirebaseAuthException catch (e) {
                    // Trata erros comuns do Firebase
                    String message = 'Ocorreu um erro.';
                    if (e.code == 'weak-password') {
                      message = 'A senha é muito fraca.';
                    } else if (e.code == 'email-already-in-use') {
                      message = 'Este email já está em uso.';
                    } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
                      message = 'Email ou senha inválidos.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
                },
                child: Text(isSignUp ? 'Cadastre-se' : 'Entre em sua conta'),
              ),
              TextButton(
                onPressed: toggleForm,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlueAccent,
                ),
                child: Text(isSignUp
                    ? 'Já possui uma conta? Entre em sua conta'
                    : 'Não possui uma? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}