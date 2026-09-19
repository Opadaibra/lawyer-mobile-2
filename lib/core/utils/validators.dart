class AppValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required / البريد الإلكتروني مطلوب';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Invalid email / بريد إلكتروني غير صالح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required / كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'Minimum 6 characters / 6 أحرف على الأقل';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password / أكد كلمة المرور';
    }
    if (value != password) {
      return 'Passwords do not match / كلمات المرور غير متطابقة';
    }
    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "This field"} is required / هذا الحقل مطلوب';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^\+?[\d\s\-]{8,15}$').hasMatch(value.trim())) {
      return 'Invalid phone / رقم هاتف غير صالح';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required / الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'Name too short / الاسم قصير جداً';
    }
    return null;
  }
}
