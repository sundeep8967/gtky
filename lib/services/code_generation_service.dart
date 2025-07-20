import 'dart:math';

class CodeGenerationService {
  static final CodeGenerationService _instance = CodeGenerationService._internal();
  factory CodeGenerationService() => _instance;
  CodeGenerationService._internal();

  final Random _random = Random();

  /// Generate a unique 2-digit code for a user
  String generateUserCode() {
    // Generate a 2-digit code (10-99)
    int code = _random.nextInt(90) + 10;
    return code.toString();
  }

  /// Generate codes for all members of a dining plan
  Map<String, String> generateCodesForPlan(List<String> memberIds) {
    Map<String, String> codes = {};
    Set<String> usedCodes = {};
    
    for (String memberId in memberIds) {
      String code;
      do {
        code = generateUserCode();
      } while (usedCodes.contains(code));
      
      usedCodes.add(code);
      codes[memberId] = code;
    }
    
    return codes;
  }

  /// Validate if a code is in the correct format
  bool isValidCodeFormat(String code) {
    if (code.length != 2) return false;
    int? codeInt = int.tryParse(code);
    return codeInt != null && codeInt >= 10 && codeInt <= 99;
  }

  /// Generate a verification code for restaurant staff
  String generateVerificationCode() {
    // Generate a 4-digit verification code for restaurant staff
    int code = _random.nextInt(9000) + 1000;
    return code.toString();
  }
}