import 'dart:convert';

/// Authentication Configuration Validator
class AuthValidator {
  /// Validate basic authentication credentials
  static AuthValidationResult validateBasicAuth(String? username, String? password) {
    if (username == null || username.isEmpty) {
      return AuthValidationResult(
        isValid: false,
        error: 'Username is required for basic authentication',
        suggestion: 'Enter your Elasticsearch username',
      );
    }
    
    if (password == null || password.isEmpty) {
      return AuthValidationResult(
        isValid: false,
        error: 'Password is required for basic authentication',
        suggestion: 'Enter your Elasticsearch password',
      );
    }
    
    // Check for problematic characters
    if (username.contains(':')) {
      return AuthValidationResult(
        isValid: false,
        error: 'Username cannot contain colon (:) character',
        suggestion: 'Use a different username or escape the character',
      );
    }
    
    // Test base64 encoding
    try {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));
      base64Decode(encoded); // Verify it can be decoded
      
      return AuthValidationResult(
        isValid: true,
        encodedCredentials: encoded,
      );
    } catch (e) {
      return AuthValidationResult(
        isValid: false,
        error: 'Failed to encode credentials: $e',
        suggestion: 'Check for special characters in username or password',
      );
    }
  }
  
  /// Validate API key format
  static AuthValidationResult validateApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return AuthValidationResult(
        isValid: false,
        error: 'API key is required',
        suggestion: 'Enter your Elasticsearch API key',
      );
    }
    
    // Basic format validation
    if (apiKey.contains(':') && !apiKey.contains('==')) {
      return AuthValidationResult(
        isValid: false,
        error: 'API key appears to be in id:secret format',
        suggestion: 'Use the base64-encoded API key instead',
      );
    }
    
    // Check if it looks like base64
    try {
      if (apiKey.length % 4 == 0 && RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(apiKey)) {
        return AuthValidationResult(isValid: true);
      } else {
        return AuthValidationResult(
          isValid: true, // Still allow it, might be a different format
          warning: 'API key format looks unusual, but will be attempted',
        );
      }
    } catch (e) {
      return AuthValidationResult(
        isValid: false,
        error: 'Invalid API key format: $e',
        suggestion: 'Ensure you have the correct API key from Elasticsearch',
      );
    }
  }
  
  /// Get authentication header preview
  static String getAuthHeaderPreview({String? username, String? password, String? apiKey}) {
    if (apiKey != null && apiKey.isNotEmpty) {
      return 'Authorization: ApiKey ${apiKey.length > 20 ? '${apiKey.substring(0, 20)}...' : apiKey}';
    } else if (username != null && password != null && username.isNotEmpty && password.isNotEmpty) {
      final result = validateBasicAuth(username, password);
      if (result.isValid && result.encodedCredentials != null) {
        final encoded = result.encodedCredentials!;
        return 'Authorization: Basic ${encoded.length > 20 ? '${encoded.substring(0, 20)}...' : encoded}';
      } else {
        return 'Authorization: Basic <invalid encoding>';
      }
    } else {
      return 'No authentication configured';
    }
  }
}

/// Result of authentication validation
class AuthValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;
  final String? suggestion;
  final String? encodedCredentials;
  
  const AuthValidationResult({
    required this.isValid,
    this.error,
    this.warning,
    this.suggestion,
    this.encodedCredentials,
  });
  
  bool get hasError => error != null;
  bool get hasWarning => warning != null;
  bool get hasSuggestion => suggestion != null;
}