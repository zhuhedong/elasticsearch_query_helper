import 'dart:convert';

/// Authentication Test Utility
/// This utility helps debug authentication issues with Elasticsearch
class AuthTestUtil {
  /// Test basic authentication encoding
  static String testBasicAuth(String username, String password) {
    final credentials = '$username:$password';
    final encoded = base64Encode(utf8.encode(credentials));
    
    print('Testing Basic Authentication:');
    print('Username: $username');
    print('Password: ${password.replaceAll(RegExp(r'.'), '*')}');
    print('Credentials string: $credentials');
    print('Base64 encoded: $encoded');
    print('Authorization header: Basic $encoded');
    
    return encoded;
  }
  
  /// Validate base64 encoding
  static bool validateBase64(String encoded) {
    try {
      base64Decode(encoded);
      return true;
    } catch (e) {
      print('Invalid base64 encoding: $e');
      return false;
    }
  }
  
  /// Test API key format
  static bool testApiKey(String apiKey) {
    print('Testing API Key:');
    print('API Key: ${apiKey.substring(0, 10)}...');
    print('Authorization header: ApiKey $apiKey');
    
    // Basic validation - API keys should be base64-like strings
    return apiKey.isNotEmpty && !apiKey.contains(':');
  }
  
  /// Debug authentication headers
  static Map<String, String> debugHeaders({
    String? username,
    String? password,
    String? apiKey,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    print('\n=== Authentication Debug ===');
    
    if (apiKey != null) {
      print('Using API Key authentication');
      if (testApiKey(apiKey)) {
        headers['Authorization'] = 'ApiKey $apiKey';
      } else {
        print('ERROR: Invalid API key format');
      }
    } else if (username != null && password != null) {
      print('Using Basic authentication');
      final encoded = testBasicAuth(username, password);
      if (validateBase64(encoded)) {
        headers['Authorization'] = 'Basic $encoded';
      } else {
        print('ERROR: Invalid base64 encoding');
      }
    } else {
      print('No authentication configured');
    }
    
    print('\nFinal headers:');
    headers.forEach((key, value) {
      if (key == 'Authorization') {
        print('$key: ${value.substring(0, 20)}...');
      } else {
        print('$key: $value');
      }
    });
    print('=== End Debug ===\n');
    
    return headers;
  }
  
  /// Common authentication issues and solutions
  static void printTroubleshootingGuide() {
    print('''
=== Elasticsearch Authentication Troubleshooting ===

Common Issues and Solutions:

1. 401 Authentication Error with "invalid basic authentication header encoding"
   - Cause: Incorrect base64 encoding of username:password
   - Solution: Ensure proper base64 encoding (not URL encoding)
   - Check: Username and password don't contain special characters

2. 401 with "illegal base64 character 3a"
   - Cause: Colon (:) character not properly encoded
   - Solution: Use base64Encode(utf8.encode("username:password"))
   - Avoid: Using Uri.encodeFull() for basic auth

3. API Key Authentication Issues
   - Format: "ApiKey <key_value>"
   - Not: "Bearer <key_value>"
   - Ensure: No extra spaces or characters

4. Connection Refused
   - Check: Elasticsearch is running
   - Verify: Host and port are correct
   - Test: Network connectivity

5. SSL/TLS Issues
   - Use: https:// for secure connections
   - Check: Certificate validity
   - Consider: Self-signed certificate handling

Quick Test Commands:
- curl -u username:password http://localhost:9200/
- curl -H "Authorization: ApiKey <key>" http://localhost:9200/
- echo -n "username:password" | base64

=== End Troubleshooting Guide ===
''');
  }
}