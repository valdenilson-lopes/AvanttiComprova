class CnpjValidator {
  /// Valida um CNPJ (formato: 99.999.999/9999-99 ou apenas números)
  static bool isValid(String cnpj) {
    if (cnpj.isEmpty) return false;

    // Remove caracteres não numéricos
    cnpj = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica se tem 14 dígitos
    if (cnpj.length != 14) return false;

    // Verifica se todos os dígitos são iguais (ex: 11111111111111)
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;

    // Valida dígitos verificadores
    return _validarDigitos(cnpj);
  }

  /// Valida os dois dígitos verificadores do CNPJ
  static bool _validarDigitos(String cnpj) {
    // Cálculo do primeiro dígito verificador
    int soma = 0;
    int peso = 5;

    for (int i = 0; i < 12; i++) {
      soma += int.parse(cnpj[i]) * peso;
      peso = peso == 2 ? 9 : peso - 1;
    }

    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;

    // Cálculo do segundo dígito verificador
    soma = 0;
    peso = 6;

    for (int i = 0; i < 13; i++) {
      soma += int.parse(cnpj[i]) * peso;
      peso = peso == 2 ? 9 : peso - 1;
    }

    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;

    // Verifica se os dígitos calculados são iguais aos informados
    return cnpj[12] == digito1.toString() && cnpj[13] == digito2.toString();
  }

  /// Formata um CNPJ (adiciona máscara)
  static String formatar(String cnpj) {
    cnpj = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpj.length != 14) return cnpj;

    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  /// Remove a máscara do CNPJ
  static String limpar(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Gera um CNPJ válido para testes
  static String gerarCnpjValido() {
    // Gera os primeiros 12 dígitos aleatórios
    String cnpjBase = '';
    for (int i = 0; i < 12; i++) {
      cnpjBase += (DateTime.now().microsecondsSinceEpoch % 9 + 1).toString();
    }

    // Calcula os dígitos verificadores
    String cnpjCompleto = cnpjBase + _calcularDigitos(cnpjBase);

    return cnpjCompleto;
  }

  /// Calcula os dígitos verificadores para uma base de CNPJ
  static String _calcularDigitos(String base) {
    // Primeiro dígito
    int soma = 0;
    int peso = 5;

    for (int i = 0; i < 12; i++) {
      soma += int.parse(base[i]) * peso;
      peso = peso == 2 ? 9 : peso - 1;
    }

    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;

    // Segundo dígito
    soma = 0;
    peso = 6;
    String baseComDigito1 = base + digito1.toString();

    for (int i = 0; i < 13; i++) {
      soma += int.parse(baseComDigito1[i]) * peso;
      peso = peso == 2 ? 9 : peso - 1;
    }

    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;

    return digito1.toString() + digito2.toString();
  }
}
