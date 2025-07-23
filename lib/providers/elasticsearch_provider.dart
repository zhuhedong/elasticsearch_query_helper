import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/elasticsearch_config.dart';
import '../models/search_result.dart';
import '../services/elasticsearch_service.dart';

class ElasticsearchProvider extends ChangeNotifier {
  ElasticsearchConfig? _config;
  ElasticsearchService? _service;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;
  SearchResult? _lastSearchResult;
  List<Map<String, dynamic>> _indices = [];
  Map<String, dynamic>? _clusterHealth;
  List<ElasticsearchConfig> _savedConfigs = [];
  String? _selectedIndex;

  // Getters
  ElasticsearchConfig? get config => _config;
  ElasticsearchService? get service => _service;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SearchResult? get lastSearchResult => _lastSearchResult;
  List<Map<String, dynamic>> get indices => _indices;
  Map<String, dynamic>? get clusterHealth => _clusterHealth;
  List<ElasticsearchConfig> get savedConfigs => _savedConfigs;
  String? get selectedIndex => _selectedIndex;

  ElasticsearchProvider() {
    loadSavedConnections();
  }

  /// Load saved configurations from SharedPreferences
  Future<void> loadSavedConnections() async {
    try {
      print('DEBUG: Loading saved connections...');
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getStringList('saved_configs') ?? [];
      print('DEBUG: Found ${configsJson.length} saved configs in SharedPreferences');
      
      _savedConfigs = configsJson
          .map((json) {
            try {
              return ElasticsearchConfig.fromJson(jsonDecode(json));
            } catch (e) {
              print('DEBUG: Failed to parse config JSON: $json, error: $e');
              return null;
            }
          })
          .where((config) => config != null)
          .cast<ElasticsearchConfig>()
          .toList();
      
      print('DEBUG: Successfully loaded ${_savedConfigs.length} valid configs');
      for (int i = 0; i < _savedConfigs.length; i++) {
        final config = _savedConfigs[i];
        print('DEBUG: Config $i: ${config.host}:${config.port} (${config.version})');
      }
      
      notifyListeners();
    } catch (e) {
      print('DEBUG: loadSavedConnections error: $e');
      _setError('Failed to load saved configurations: $e');
    }
  }

  /// Save a new connection or update existing one
  Future<void> saveConnection(ElasticsearchConfig config) async {
    try {
      print('DEBUG: Saving connection - Host: ${config.host}:${config.port}');
      print('DEBUG: Current saved configs count: ${_savedConfigs.length}');
      
      // Remove existing config with same host:port if updating
      _savedConfigs.removeWhere((c) => 
          c.host == config.host && c.port == config.port);
      
      // Add the new/updated config at the beginning
      _savedConfigs.insert(0, config);
      
      print('DEBUG: After adding, saved configs count: ${_savedConfigs.length}');
      
      // Keep only the last 20 connections
      if (_savedConfigs.length > 20) {
        _savedConfigs = _savedConfigs.take(20).toList();
      }
      
      await _saveConfigs();
      print('DEBUG: Connection saved successfully');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Failed to save connection: $e');
      _setError('Failed to save connection: $e');
      rethrow;
    }
  }

  /// Save configurations to SharedPreferences
  Future<void> _saveConfigs() async {
    try {
      print('DEBUG: Saving ${_savedConfigs.length} configs to SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final configsJson = _savedConfigs
          .map((config) => jsonEncode(config.toJson()))
          .toList();
      print('DEBUG: Configs JSON length: ${configsJson.length}');
      final result = await prefs.setStringList('saved_configs', configsJson);
      print('DEBUG: SharedPreferences save result: $result');
      
      // Verify save by reading back
      final saved = prefs.getStringList('saved_configs');
      print('DEBUG: Verification - saved configs count: ${saved?.length ?? 0}');
    } catch (e) {
      print('DEBUG: _saveConfigs error: $e');
      _setError('Failed to save configurations: $e');
    }
  }

  /// Set configuration and create service
  Future<void> setConfig(ElasticsearchConfig config) async {
    _setLoading(true);
    _config = config;
    _service?.dispose();
    _service = ElasticsearchService(config);
    _isConnected = false;
    
    // Save to recent configs if not already saved
    if (!_savedConfigs.any((c) => 
        c.host == config.host && 
        c.port == config.port && 
        c.version == config.version)) {
      _savedConfigs.insert(0, config);
      if (_savedConfigs.length > 10) {
        _savedConfigs.removeLast();
      }
      await _saveConfigs();
    }
    
    _setLoading(false);
    notifyListeners();
  }

  /// Test connection to Elasticsearch
  Future<bool> testConnection() async {
    final service = _service;
    if (service == null) {
      print('ElasticsearchProvider: Service is null');
      return false;
    }
    
    print('ElasticsearchProvider: Starting connection test...');
    _setLoading(true);
    try {
      // Add timeout to prevent hanging
      print('ElasticsearchProvider: Calling service.testConnection()...');
      final result = await service.testConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('ElasticsearchProvider: Service timeout occurred');
          return {
            'success': false,
            'error': 'Connection timeout after 10 seconds'
          };
        },
      );
      
      print('ElasticsearchProvider: Service returned result: $result');
      _isConnected = result['success'] == true;
      
      if (_isConnected) {
        print('ElasticsearchProvider: Connection successful');
        _clearError();
        await _loadClusterInfo();
        // Auto-load indices after successful connection
        print('DEBUG: Auto-loading indices after successful connection');
        await loadIndices();
      } else {
        print('ElasticsearchProvider: Connection failed: ${result['error']}');
        _setError(result['error'] ?? 'Connection failed');
      }
      
      return _isConnected;
    } catch (e) {
      print('ElasticsearchProvider: Exception occurred: $e');
      _setError(e.toString());
      _isConnected = false;
      return false;
    } finally {
      print('ElasticsearchProvider: Setting loading to false');
      _setLoading(false);
    }
  }

  /// Load cluster information
  Future<void> _loadClusterInfo() async {
    final service = _service;
    if (service == null) return;
    
    try {
      _clusterHealth = await service.getClusterHealth();
      _indices = await service.getIndices();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load cluster info: $e');
    }
  }

  /// Execute search query
  Future<SearchResult?> search({
    required String index,
    required Map<String, dynamic> query,
    int? size,
    int? from,
  }) async {
    final service = _service;
    if (service == null) {
      final error = 'Elasticsearch service not initialized. Please configure connection first.';
      _setError(error);
      throw Exception(error);
    }
    
    if (!_isConnected) {
      final error = 'Not connected to Elasticsearch. Please test connection first.';
      _setError(error);
      throw Exception(error);
    }

    _setLoading(true);
    try {
      print('Executing search on index: $index');
      print('Query: ${json.encode(query)}');
      print('Size: $size, From: $from');
      
      _lastSearchResult = await service.search(
        index: index,
        query: query,
        size: size,
        from: from,
      );
      
      print('Search successful: ${_lastSearchResult?.hits.total.value} results');
      _clearError();
      return _lastSearchResult;
    } catch (e) {
      final errorMsg = 'Search failed: $e';
      print('Search error: $errorMsg');
      _setError(errorMsg);
      throw Exception(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  /// Execute raw query
  Future<Map<String, dynamic>?> rawQuery({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final service = _service;
    if (service == null || !_isConnected) {
      _setError('Not connected to Elasticsearch');
      return null;
    }

    _setLoading(true);
    try {
      final result = await service.rawQuery(
        method: method,
        endpoint: endpoint,
        body: body,
      );
      _clearError();
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get query templates
  List<QueryTemplate> getQueryTemplates() {
    return _service?.getQueryTemplates() ?? [];
  }

  /// Validate query
  bool validateQuery(Map<String, dynamic> query) {
    return _service?.validateQuery(query) ?? false;
  }

  /// Get mapping for index
  Future<Map<String, dynamic>?> getMapping(String index) async {
    final service = _service;
    if (service == null || !_isConnected) {
      _setError('Not connected to Elasticsearch');
      return null;
    }

    _setLoading(true);
    try {
      final mapping = await service.getMapping(index);
      _clearError();
      return mapping;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify connection before performing operations
  Future<bool> verifyConnection() async {
    final service = _service;
    if (service == null) {
      _setError('Service not initialized');
      return false;
    }

    try {
      final result = await service.testConnection();
      _isConnected = result['success'] == true;
      
      if (_isConnected) {
        _clearError();
        // Refresh cluster info
        await _loadClusterInfo();
        // Auto-load indices after successful verification
        print('DEBUG: Auto-loading indices after connection verification');
        await loadIndices();
      } else {
        _setError(result['error'] ?? 'Connection verification failed');
      }
      
      return _isConnected;
    } catch (e) {
      _setError('Connection verification error: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Set selected index
  void setSelectedIndex(String? index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// Load indices
  Future<void> loadIndices() async {
    final service = _service;
    if (service == null || !_isConnected) {
      print('DEBUG: loadIndices failed - service: $service, connected: $_isConnected');
      _setError('Not connected to Elasticsearch');
      return;
    }

    print('DEBUG: Starting loadIndices...');
    _setLoading(true);
    try {
      print('DEBUG: Calling service.getIndices()...');
      _indices = await service.getIndices();
      print('DEBUG: Received ${_indices.length} indices');
      if (_indices.isNotEmpty) {
        print('DEBUG: First index: ${_indices.first}');
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      print('DEBUG: loadIndices error: $e');
      _setError('Failed to load indices: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove saved configuration
  Future<void> removeSavedConfig(ElasticsearchConfig config) async {
    _savedConfigs.removeWhere((c) => 
        c.host == config.host && 
        c.port == config.port && 
        c.version == config.version);
    await _saveConfigs();
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _service?.dispose();
    _service = null;
    _config = null;
    _isConnected = false;
    _lastSearchResult = null;
    _indices.clear();
    _clusterHealth = null;
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}