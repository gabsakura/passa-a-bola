import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/constants.dart';
import '../utils/text_formatters.dart';

class FormattedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final int maxLines;
  final FormattedFieldType fieldType;

  const FormattedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.hintText,
    required this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    required this.fieldType,
  });

  @override
  State<FormattedTextField> createState() => _FormattedTextFieldState();
}

class _FormattedTextFieldState extends State<FormattedTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: KInputDecoration.textFieldDecoration(
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        hintText: widget.hintText ?? _getDefaultHint(),
      ),
      keyboardType: widget.keyboardType,
      inputFormatters: _getInputFormatters(),
      maxLines: widget.maxLines,
      onChanged: _onTextChanged,
      validator: widget.validator ?? _getDefaultValidator(),
    );
  }

  String _getDefaultHint() {
    switch (widget.fieldType) {
      case FormattedFieldType.phone:
        return '(11) 99999-9999';
      case FormattedFieldType.birthDate:
        return 'DD/MM/AAAA';
      case FormattedFieldType.cpf:
        return '000.000.000-00';
      case FormattedFieldType.cep:
        return '00000-000';
      case FormattedFieldType.normal:
        return '';
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.fieldType) {
      case FormattedFieldType.phone:
        return [
          TextFormatters.phoneFormatter,
          LengthLimitingTextInputFormatter(11), // Máximo 11 dígitos
        ];
      case FormattedFieldType.birthDate:
        return [
          TextFormatters.dateFormatter,
          LengthLimitingTextInputFormatter(8), // Máximo 8 dígitos (DDMMAAAA)
        ];
      case FormattedFieldType.cpf:
        return [
          TextFormatters.cpfFormatter,
          LengthLimitingTextInputFormatter(11), // Máximo 11 dígitos
        ];
      case FormattedFieldType.cep:
        return [
          TextFormatters.cepFormatter,
          LengthLimitingTextInputFormatter(8), // Máximo 8 dígitos
        ];
      case FormattedFieldType.normal:
        return [];
    }
  }

  void _onTextChanged(String value) {
    String formatted = value;

    switch (widget.fieldType) {
      case FormattedFieldType.phone:
        formatted = TextFormatters.formatPhone(value);
        break;
      case FormattedFieldType.birthDate:
        formatted = TextFormatters.formatBirthDate(value);
        break;
      case FormattedFieldType.cpf:
        formatted = TextFormatters.formatCPF(value);
        break;
      case FormattedFieldType.cep:
        formatted = TextFormatters.formatCEP(value);
        break;
      case FormattedFieldType.normal:
        // Não formata campos normais, mas chama o callback
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
        return;
    }

    // Só atualiza se o valor formatado for diferente e não estiver vazio
    if (formatted != value && formatted.isNotEmpty) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Chama o callback com o valor formatado
    if (widget.onChanged != null) {
      widget.onChanged!(formatted);
    }
  }

  String? Function(String?) _getDefaultValidator() {
    return (value) {
      if (value == null || value.isEmpty) {
        return '${widget.labelText} é obrigatório';
      }

      switch (widget.fieldType) {
        case FormattedFieldType.phone:
          if (!TextFormatters.isValidPhone(value)) {
            return 'Telefone inválido';
          }
          break;
        case FormattedFieldType.birthDate:
          if (!TextFormatters.isValidBirthDate(value)) {
            return 'Data de nascimento inválida';
          }
          break;
        case FormattedFieldType.cpf:
          if (!TextFormatters.isValidCPF(value)) {
            return 'CPF inválido';
          }
          break;
        case FormattedFieldType.cep:
          if (!TextFormatters.isValidCEP(value)) {
            return 'CEP inválido';
          }
          break;
        case FormattedFieldType.normal:
          break; // Sem validação especial para campos normais
      }

      return null;
    };
  }
}

enum FormattedFieldType { phone, birthDate, cpf, cep, normal }
