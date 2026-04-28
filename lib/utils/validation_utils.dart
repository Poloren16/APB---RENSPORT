class ValidationUtils {
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Kata sandi minimal 8 karakter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Kata sandi harus mengandung minimal satu huruf kapital.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Kata sandi harus mengandung minimal satu huruf kecil.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Kata sandi harus mengandung minimal satu angka.';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Kata sandi harus mengandung minimal satu karakter spesial (contoh: !@#\$%).';
    }
    return null;
  }
}
