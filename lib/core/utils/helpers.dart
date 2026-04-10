import 'package:app/core/utils/cnpj_validator.dart';

class Helpers {
  static String formatCnpj(String cnpj) {
    return CnpjValidator.formatar(cnpj);
  }

  static String cleanCnpj(String cnpj) {
    return CnpjValidator.limpar(cnpj);
  }

  static bool isValidCnpj(String cnpj) {
    return CnpjValidator.isValid(cnpj);
  }
}
