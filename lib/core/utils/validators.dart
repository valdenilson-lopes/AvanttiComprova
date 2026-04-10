class Validators {
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^0-9]'), ''));
  }
}
