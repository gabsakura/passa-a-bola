import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../utils/responsive.dart';
import '../widgets/login_form.dart';
import '../widgets/web_login_hero.dart';
import 'cadastro.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um error';
      if (e.code == 'user-not-found') {
        message = 'Nenhum usuario encontrado com esse gmail.';
      } else if (e.code == 'wrong-password') {
        message = 'senha incorreta';
      } else if (e.code == 'invalid-credential') {
        message = 'Email ou senhas invalidas';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha inesperada'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToCadastro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CadastroPage()),
    );
  }

  Widget _buildForm() {
    return LoginForm(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      rememberMe: _rememberMe,
      isLoading: _isLoading,
      onRememberMeChanged: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
      onSubmit: _login,
      onCadastro: _goToCadastro,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.useWebLogin(context)) {
      return Scaffold(
        backgroundColor: KConstants.backgroundColor,
        body: Row(
          children: [
            const Expanded(flex: 5, child: WebLoginHero()),
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: KConstants.backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }
}
