import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/elasticsearch_config.dart';
import '../models/search_result.dart';
import '../utils/auth_test_util.dart';
import 'version_adapter.dart';

class ElasticsearchService {
  final ElasticsearchConfig config;
  late final ElasticsearchVersionAdapter adapter;
  late final http.Client _client;

  ElasticsearchService(this.config) {
    adapter = AdapterFactory.createAdapter(config.version);
    _client = http.Client();
  }

  /// Safely parse JSON with proper error handling
  static dynamic _safeJsonDecode(String body, {dynamic fallback}) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return fallback;
    }
    try {
      return json.decode(trimmedBody);
    } catch (e) {
      throw FormatException('Failed to parse JSON response: $e\nResponse body: $trimmedBody');
    }
  }

  void dispose() {
    _client.close();
  }

  /// Test connection to Elasticsearch cluster
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Debug authentication headers if needed
      if (config.username != null || config.apiKey != null) {
        print('Debug mode: Testing authentication...');
        AuthTestUtil.debugHeaders(
          username: config.username,
          password: config.password,
          apiKey: config.apiKey,
        );
      }

      final response = await _client.get(
        Uri.parse('${config.baseUrl}/'),
        headers: config.headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body, fallback: {});
        return {
          'success': true,
          'version': data['version']?['number'] ?? 'unknown',
          'cluster_name': data['cluster_name'] ?? 'unknown',
          'tagline': data['tagline'] ?? '',
        };
      } else if (response.statusCode == 401) {
        final errorBody = _safeJsonDecode(response.body, fallback: null);
        final errorMessage = errorBody?['error']?['reason'] ?? 'Authentication failed';
        
        // Print troubleshooting guide for authentication errors
        print('Authentication failed. Printing troubleshooting guide:');
        AuthTestUtil.printTroubleshootingGuide();
        
        return {
          'success': false,
          'error': 'Authentication Error (401): $errorMessage\n\nPlease check your username and password.\n\nCommon fixes:\n- Ensure username and password are correct\n- Check for special characters in credentials\n- Verify Elasticsearch security is properly configured',
        };
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'Unknown error';
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: $errorBody',
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}\n\nPlease check:\n- Elasticsearch is running\n- Host and port are correct\n- Network connectivity',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'error': 'HTTP error: ${e.message}',
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'error': 'Invalid response format: ${e.message}',
      };
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'error': 'Connection timeout after 10 seconds\n\nPlease check:\n- Elasticsearch is running\n- Host and port are correct\n- Network connectivity',
        };
      }
      return {
        'success': false,
        'error': 'Connection failed: $e',
      };
    }
  }

  /// Get cluster health
  Future<Map<String, dynamic>> getClusterHealth() async {
    try {
      final endpoint = adapter.endpoints['health']!;
      final response = await _client.get(
        Uri.parse('${config.baseUrl}$endpoint'),
        headers: config.headers,
      );

      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body, fallback: {});
      } else {
        throw Exception('Failed to get cluster health: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting cluster health: $e');
    }
  }

  /// Get list of indices
  Future<List<Map<String, dynamic>>> getIndices() async {
    try {
      final endpoint = adapter.endpoints['indices']!;
      final url = '${config.baseUrl}$endpoint?format=json';
      print('DEBUG: getIndices URL: $url');
      
      final response = await _client.get(
        Uri.parse(url),
        headers: config.headers,
      );

      print('DEBUG: getIndices response status: ${response.statusCode}');
      print('DEBUG: getIndices response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = _safeJsonDecode(response.body, fallback: []);
        print('DEBUG: Parsed ${data.length} indices from response');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('DEBUG: getIndices failed with status: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');
        throw Exception('Failed to get indices: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: getIndices exception: $e');
      throw Exception('Error getting indices: $e');
    }
  }

  /// Get mapping for an index
  Future<Map<String, dynamic>> getMapping(String index) async {
    try {
      final endpoint = adapter.endpoints['mapping']!.replaceAll('{index}', index);
      final response = await _client.get(
        Uri.parse('${config.baseUrl}$endpoint'),
        headers: config.headers,
      );

      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body, fallback: {});
      } else {
        throw Exception('Failed to get mapping: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting mapping: $e');
    }
  }

  /// Execute search query
  Future<SearchResult> search({
    required String index,
    required Map<String, dynamic> query,
    int? size,
    int? from,
  }) async {
    try {
      // Validate query compatibility
      if (!adapter.isQueryCompatible(query)) {
        throw Exception('Query not compatible with ${adapter.version}');
      }

      // Adapt query for the specific version
      final adaptedQuery = adapter.adaptQuery(query);
      
      // Add size and from parameters if provided
      if (size != null) adaptedQuery['size'] = size;
      if (from != null) adaptedQuery['from'] = from;

      final endpoint = adapter.endpoints['search']!.replaceAll('{index}', index);
      
      // First try to get index mapping to understand the structure
      try {
        await getMapping(index);
        print('Index mapping retrieved successfully');
      } catch (mappingError) {
        print('Warning: Could not retrieve index mapping: $mappingError');
      }
      
      final response = await _client.post(
        Uri.parse('${config.baseUrl}$endpoint'),
        headers: config.headers,
        body: json.encode(adaptedQuery),
      );

      if (response.statusCode == 200) {
        final responseData = _safeJsonDecode(response.body, fallback: null);
        if (responseData == null) {
          throw Exception('Empty response from Elasticsearch');
        }
        return adapter.adaptSearchResult(responseData);
      } else {
        final errorData = _safeJsonDecode(response.body, fallback: {'error': {'type': 'unknown', 'reason': 'Empty error response'}});
        final error = ElasticsearchError.fromJson(errorData['error'] ?? {});
        
        // Handle specific error types with fallback strategies
        if (error.type == 'search_phase_execution_exception') {
          print('Search phase execution exception detected, trying simpler query...');
          return await _executeSimpleSearch(index, size, from);
        }
        
        throw ElasticsearchException(
          statusCode: response.statusCode,
          error: error,
        );
      }
    } catch (e) {
      if (e is ElasticsearchException) rethrow;
      throw Exception('Error executing search: $e');
    }
  }

  /// Execute a simple search without complex sorting or aggregations
  Future<SearchResult> _executeSimpleSearch(String index, int? size, int? from) async {
    try {
      print('Attempting simple search without sorting...');
      
      final simpleQuery = <String, dynamic>{
        'query': {'match_all': {}},
      };
      
      // Add size and from parameters if provided
      if (size != null) simpleQuery['size'] = size;
      if (from != null) simpleQuery['from'] = from;
      
      final endpoint = adapter.endpoints['search']!.replaceAll('{index}', index);
      final response = await _client.post(
        Uri.parse('${config.baseUrl}$endpoint'),
        headers: config.headers,
        body: json.encode(simpleQuery),
      );
      
      if (response.statusCode == 200) {
        final responseData = _safeJsonDecode(response.body, fallback: null);
        if (responseData == null) {
          throw Exception('Empty response from Elasticsearch');
        }
        print('Simple search successful');
        return adapter.adaptSearchResult(responseData);
      } else {
        final errorData = _safeJsonDecode(response.body, fallback: {'error': {'type': 'unknown', 'reason': 'Empty error response'}});
        throw ElasticsearchException(
          statusCode: response.statusCode,
          error: ElasticsearchError.fromJson(errorData['error'] ?? {}),
        );
      }
    } catch (e) {
      print('Simple search also failed: $e');
      throw Exception('All search attempts failed: $e');
    }
  }

  /// Execute raw query (for advanced users)
  Future<Map<String, dynamic>> rawQuery({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      late http.Response response;
      final uri = Uri.parse('${config.baseUrl}$endpoint');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: config.headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: config.headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: config.headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: config.headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return {
        'statusCode': response.statusCode,
        'body': _safeJsonDecode(response.body, fallback: null),
        'success': response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      throw Exception('Error executing raw query: $e');
    }
  }

  /// Get query templates for current version
  List<QueryTemplate> getQueryTemplates() {
    return adapter.queryTemplates;
  }

  /// Validate query syntax
  bool validateQuery(Map<String, dynamic> query) {
    try {
      json.encode(query);
      return adapter.isQueryCompatible(query);
    } catch (e) {
      return false;
    }
  }
}

class ElasticsearchException implements Exception {
  final int statusCode;
  final ElasticsearchError error;

  ElasticsearchException({
    required this.statusCode,
    required this.error,
  });

  @override
  String toString() {
    return 'ElasticsearchException: ${error.type} - ${error.reason}';
  }
}