import 'package:flutter/services.dart';

class TextFormatters {
  // Formatação de data (DD/MM/AAAA) - apenas números
  static TextInputFormatter get dateFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  // Formatação de CPF (000.000.000-00) - apenas números
  static TextInputFormatter get cpfFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  // Formatação de telefone ((11) 99999-9999) - apenas números
  static TextInputFormatter get phoneFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  // Formatação de CEP (00000-000) - apenas números
  static TextInputFormatter get cepFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  // Máscara para data de nascimento
  static String formatBirthDate(String value) {
    // Remove todos os caracteres não numéricos
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 8 dígitos (DDMMAAAA)
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    // Aplica formatação baseada no número de dígitos
    if (digitsOnly.isEmpty) {
      return '';
    } else if (digitsOnly.length <= 2) {
      return digitsOnly;
    } else if (digitsOnly.length <= 4) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    } else if (digitsOnly.length <= 6) {
      // Para 5-6 dígitos: DD/MM/YY
      String day = digitsOnly.substring(0, 2);
      String month = digitsOnly.substring(2, 4);
      String year = digitsOnly.substring(4);
      return '$day/$month/$year';
    } else {
      // Para 7-8 dígitos: DD/MM/YYYY
      String day = digitsOnly.substring(0, 2);
      String month = digitsOnly.substring(2, 4);
      String year = digitsOnly.substring(4);
      return '$day/$month/$year';
    }
  }

  // Máscara para CPF
  static String formatCPF(String value) {
    // Remove todos os caracteres não numéricos
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 11 dígitos
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 6) {
      return '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3)}';
    } else if (digitsOnly.length <= 9) {
      return '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3, 6)}.${digitsOnly.substring(6)}';
    } else {
      return '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3, 6)}.${digitsOnly.substring(6, 9)}-${digitsOnly.substring(9, 11)}';
    }
  }

  // Máscara para telefone
  static String formatPhone(String value) {
    // Remove todos os caracteres não numéricos
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 11 dígitos (DDD + 9 dígitos)
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    if (digitsOnly.length <= 2) {
      return digitsOnly;
    } else if (digitsOnly.length <= 6) {
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2)}';
    } else if (digitsOnly.length <= 10) {
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
    } else {
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 7)}-${digitsOnly.substring(7, 11)}';
    }
  }

  // Máscara para CEP
  static String formatCEP(String value) {
    // Remove todos os caracteres não numéricos
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 8 dígitos
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    if (digitsOnly.length <= 5) {
      return digitsOnly;
    } else {
      return '${digitsOnly.substring(0, 5)}-${digitsOnly.substring(5, 8)}';
    }
  }

  // Validação de data de nascimento
  static bool isValidBirthDate(String date) {
    if (date.length != 10) return false;

    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      // Validações básicas
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;

      // Verificar se a data existe
      final dateTime = DateTime(year, month, day);
      if (dateTime.year != year ||
          dateTime.month != month ||
          dateTime.day != day) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Validação de CPF
  static bool isValidCPF(String cpf) {
    // Remove formatação
    String digitsOnly = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length != 11) return false;

    // Verifica se todos os dígitos são iguais
    if (digitsOnly.split('').every((digit) => digit == digitsOnly[0])) {
      return false;
    }

    // Validação do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digitsOnly[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;

    if (int.parse(digitsOnly[9]) != firstDigit) return false;

    // Validação do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digitsOnly[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;

    return int.parse(digitsOnly[10]) == secondDigit;
  }

  // Validação de telefone
  static bool isValidPhone(String phone) {
    String digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Telefone deve ter exatamente 10 ou 11 dígitos
    return digitsOnly.length == 10 || digitsOnly.length == 11;
  }

  // Validação de CEP
  static bool isValidCEP(String cep) {
    String digitsOnly = cep.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length == 8;
  }

  // Formatação para exibição de data
  static String formatDisplayDate(String date) {
    if (date.isEmpty) return 'Não informado';

    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$day/$month/$year';
      }
    } catch (e) {
      // Se houver erro na formatação, retorna o valor original
    }

    return date;
  }

  // Formatação para exibição de CPF
  static String formatDisplayCPF(String cpf) {
    if (cpf.isEmpty) return 'Não informado';
    return formatCPF(cpf);
  }

  // Formatação para exibição de telefone
  static String formatDisplayPhone(String phone) {
    if (phone.isEmpty) return 'Não informado';
    return formatPhone(phone);
  }

  // Formatação para exibição de CEP
  static String formatDisplayCEP(String cep) {
    if (cep.isEmpty) return 'Não informado';
    return formatCEP(cep);
  }
}
