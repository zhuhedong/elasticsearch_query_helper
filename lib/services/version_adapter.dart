import '../models/search_result.dart';

abstract class ElasticsearchVersionAdapter {
  String get version;
  
  /// Adapts query for the specific version
  Map<String, dynamic> adaptQuery(Map<String, dynamic> query);
  
  /// Adapts search result from the specific version
  SearchResult adaptSearchResult(Map<String, dynamic> response);
  
  /// Gets supported endpoints for this version
  Map<String, String> get endpoints;
  
  /// Validates if a query is compatible with this version
  bool isQueryCompatible(Map<String, dynamic> query);
  
  /// Gets version-specific query templates
  List<QueryTemplate> get queryTemplates;
}

class ElasticsearchV6Adapter implements ElasticsearchVersionAdapter {
  @override
  String get version => 'v6';

  @override
  Map<String, dynamic> adaptQuery(Map<String, dynamic> query) {
    final adaptedQuery = Map<String, dynamic>.from(query);
    
    // V6 requires type in mapping
    if (adaptedQuery.containsKey('track_total_hits')) {
      adaptedQuery.remove('track_total_hits');
    }
    
    return adaptedQuery;
  }

  @override
  SearchResult adaptSearchResult(Map<String, dynamic> response) {
    // V6 returns total as a number, not an object
    if (response['hits'] != null && response['hits']['total'] is int) {
      response['hits']['total'] = {
        'value': response['hits']['total'],
        'relation': 'eq'
      };
    }
    
    return SearchResult.fromJson(response);
  }

  @override
  Map<String, String> get endpoints => {
    'search': '/{index}/_search',
    'mapping': '/{index}/_mapping',
    'indices': '/_cat/indices',
    'health': '/_cluster/health',
  };

  @override
  bool isQueryCompatible(Map<String, dynamic> query) {
    // Check for V7+ specific features
    return !query.containsKey('track_total_hits');
  }

  @override
  List<QueryTemplate> get queryTemplates => [
    QueryTemplate(
      name: 'Match All',
      description: 'Returns all documents',
      supportedVersions: ['v6', 'v7', 'v8'],
      query: {
        'query': {
          'match_all': {}
        }
      },
    ),
    QueryTemplate(
      name: 'Term Query',
      description: 'Exact term match',
      supportedVersions: ['v6', 'v7', 'v8'],
      query: {
        'query': {
          'term': {
            'field_name': 'value'
          }
        }
      },
    ),
  ];
}

class ElasticsearchV7Adapter implements ElasticsearchVersionAdapter {
  @override
  String get version => 'v7';

  @override
  Map<String, dynamic> adaptQuery(Map<String, dynamic> query) {
    final adaptedQuery = Map<String, dynamic>.from(query);
    
    // V7 supports track_total_hits
    if (!adaptedQuery.containsKey('track_total_hits')) {
      adaptedQuery['track_total_hits'] = true;
    }
    
    return adaptedQuery;
  }

  @override
  SearchResult adaptSearchResult(Map<String, dynamic> response) {
    return SearchResult.fromJson(response);
  }

  @override
  Map<String, String> get endpoints => {
    'search': '/{index}/_search',
    'mapping': '/{index}/_mapping',
    'indices': '/_cat/indices',
    'health': '/_cluster/health',
  };

  @override
  bool isQueryCompatible(Map<String, dynamic> query) {
    return true; // V7 is most compatible
  }

  @override
  List<QueryTemplate> get queryTemplates => [
    QueryTemplate(
      name: 'Match All',
      description: 'Returns all documents',
      supportedVersions: ['v6', 'v7', 'v8'],
      query: {
        'query': {
          'match_all': {}
        },
        'track_total_hits': true,
      },
    ),
    QueryTemplate(
      name: 'Bool Query',
      description: 'Boolean combination of queries',
      supportedVersions: ['v6', 'v7', 'v8'],
      query: {
        'query': {
          'bool': {
            'must': [
              {'match': {'field1': 'value1'}}
            ],
            'filter': [
              {'term': {'field2': 'value2'}}
            ]
          }
        },
        'track_total_hits': true,
      },
    ),
  ];
}

class ElasticsearchV8Adapter implements ElasticsearchVersionAdapter {
  @override
  String get version => 'v8';

  @override
  Map<String, dynamic> adaptQuery(Map<String, dynamic> query) {
    final adaptedQuery = Map<String, dynamic>.from(query);
    
    // V8 has enhanced features
    if (!adaptedQuery.containsKey('track_total_hits')) {
      adaptedQuery['track_total_hits'] = true;
    }
    
    return adaptedQuery;
  }

  @override
  SearchResult adaptSearchResult(Map<String, dynamic> response) {
    return SearchResult.fromJson(response);
  }

  @override
  Map<String, String> get endpoints => {
    'search': '/{index}/_search',
    'mapping': '/{index}/_mapping',
    'indices': '/_cat/indices',
    'health': '/_cluster/health',
  };

  @override
  bool isQueryCompatible(Map<String, dynamic> query) {
    return true; // V8 supports all features
  }

  @override
  List<QueryTemplate> get queryTemplates => [
    QueryTemplate(
      name: 'Match All',
      description: 'Returns all documents',
      supportedVersions: ['v6', 'v7', 'v8'],
      query: {
        'query': {
          'match_all': {}
        },
        'track_total_hits': true,
      },
    ),
    QueryTemplate(
      name: 'KNN Search',
      description: 'K-nearest neighbor search (V8+)',
      supportedVersions: ['v8'],
      query: {
        'knn': {
          'field': 'vector_field',
          'query_vector': [1.0, 2.0, 3.0],
          'k': 10,
          'num_candidates': 100
        }
      },
    ),
  ];
}

class AdapterFactory {
  static ElasticsearchVersionAdapter createAdapter(String version) {
    switch (version) {
      case 'v6':
        return ElasticsearchV6Adapter();
      case 'v7':
        return ElasticsearchV7Adapter();
      case 'v8':
        return ElasticsearchV8Adapter();
      default:
        throw ArgumentError('Unsupported Elasticsearch version: $version');
    }
  }
}