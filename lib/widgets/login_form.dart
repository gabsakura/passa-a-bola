import 'package:flutter/material.dart';
import '../data/constants.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isLoading;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCadastro;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.isLoading,
    required this.onRememberMeChanged,
    required this.onSubmit,
    required this.onCadastro,
  });

  @override
  Widget build(BuildContext context) {
    final isWebForm = MediaQuery.sizeOf(context).width >= 768;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWebForm) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: KConstants.primaryColor, width: 4),
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 80,
                color: KConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PASSA A BOLA',
              textAlign: TextAlign.center,
              style: KTextStyle.titleText.copyWith(
                fontSize: 28,
                color: KConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
          ] else ...[
            Text(
              'Entrar na sua conta',
              style: KTextStyle.largeTitleText.copyWith(
                color: KConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acesse campeonatos, times e notícias do futebol feminino.',
              style: KTextStyle.bodySecondaryText.copyWith(
                fontSize: KConstants.fontSizeLarge,
              ),
            ),
            const SizedBox(height: 32),
          ],
          _AuthField(
            controller: emailController,
            hint: 'EMAIL',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu email';
              }
              if (!value.contains('@')) {
                return 'Por favor, insira um email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _AuthField(
            controller: passwordController,
            hint: 'SENHA',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira sua senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Checkbox(
                value: rememberMe,
                onChanged: onRememberMeChanged,
                activeColor: KConstants.primaryColor,
              ),
              Text(
                'Lembrar-me',
                style: KTextStyle.bodyText.copyWith(
                  color: KConstants.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: KConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isWebForm ? 12 : 30,
                  ),
                ),
                elevation: isWebForm ? 0 : 5,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'ENTRAR',
                      style: KTextStyle.buttonText.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onCadastro,
            child: Text(
              'Não tem uma conta? Cadastre-se',
              style: KTextStyle.bodyText.copyWith(
                color: KConstants.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isWebForm = MediaQuery.sizeOf(context).width >= 768;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWebForm ? 12 : 30),
        border: isWebForm
            ? Border.all(color: KConstants.borderColor)
            : null,
        boxShadow: isWebForm
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: KConstants.primaryColor,
          ),
        ),
      )
    );
  }
}
