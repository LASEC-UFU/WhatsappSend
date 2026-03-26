/// Normaliza números de telefone para o formato internacional sem '+'.
/// Exemplo: '(34) 9 9111-0001' → '5534991110001'
abstract final class PhoneFormatter {
  PhoneFormatter._();

  static String format(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D+'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10 || digits.length == 11) {
      digits = '55$digits';
    }
    return digits;
  }
}
