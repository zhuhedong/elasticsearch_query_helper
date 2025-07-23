import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../theme/app_theme.dart';

class QuickSearchPanel extends StatefulWidget {
  const QuickSearchPanel({super.key});

  @override
  State<QuickSearchPanel> createState() => _QuickSearchPanelState();
}

class _QuickSearchPanelState extends State<QuickSearchPanel> {
  final _searchController = TextEditingController();
  final _fieldController = TextEditingController();
  String _searchType = 'match_all';
  String _fieldName = '';
  String _sortField = '';  // 改为空字符串，默认不排序
  String _sortOrder = 'desc';
  int _size = 10;

  @override
  void dispose() {
    _searchController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElasticsearchProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 添加这个限制
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Search',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const Spacer(),
                    if (provider.selectedIndex != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          provider.selectedIndex!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 添加这个限制
                  children: [
                    // Search type selection
                    Text(
                      'Search Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildSearchTypeChip('match_all', 'All Documents', Icons.select_all_rounded),
                        _buildSearchTypeChip('match', 'Text Search', Icons.search_rounded),
                        _buildSearchTypeChip('term', 'Exact Match', Icons.center_focus_strong_rounded),
                        _buildSearchTypeChip('range', 'Date Range', Icons.date_range_rounded),
                        _buildSearchTypeChip('wildcard', 'Wildcard', Icons.star_rounded),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Search input (conditional)
                    if (_searchType != 'match_all') ...[
                      Row(
                        children: [
                          if (_searchType != 'range') ...[
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _fieldController,
                                decoration: InputDecoration(
                                  labelText: 'Field Name',
                                  hintText: _getFieldHint(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _fieldName = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: _getSearchLabel(),
                                hintText: _getSearchHint(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Options row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortField.isEmpty ? 'none' : _sortField,
                            decoration: InputDecoration(
                              labelText: 'Sort Field',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'none',
                                child: Text('No Sorting'),
                              ),
                              const DropdownMenuItem<String>(
                                value: '@timestamp',
                                child: Text('@timestamp'),
                              ),
                              const DropdownMenuItem<String>(
                                value: '_score',
                                child: Text('_score'),
                              ),
                              const DropdownMenuItem<String>(
                                value: '_id',
                                child: Text('_id'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'created_at',
                                child: Text('created_at'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'updated_at',
                                child: Text('updated_at'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortField = value == 'none' ? '' : value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortOrder,
                            decoration: InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'desc', child: Text('Newest First')),
                              DropdownMenuItem(value: 'asc', child: Text('Oldest First')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortOrder = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Size',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _size = int.tryParse(value) ?? 10;
                              });
                            },
                            controller: TextEditingController(text: _size.toString()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Debug info
                    if (provider.selectedIndex != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // 添加这个限制
                          children: [
                            Text(
                              'Debug Info:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Connected: ${provider.isConnected}', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                            Text('Selected Index: ${provider.selectedIndex}', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                            Text('Search Type: $_searchType', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                            Text('Field Name: "$_fieldName"', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                            Text('Search Text: "${_searchController.text}"', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                            Text('Can Search: ${_canSearch(provider)}', 
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: _canSearch(provider) ? AppTheme.accentGreen : AppTheme.accentRed,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _canSearch(provider) ? () => _executeSearch(provider) : null,
                        icon: provider.isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(provider.isLoading ? 'Searching...' : 'Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          elevation: 2,
                          shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickActionChip('Last 1 hour', () => _searchLastHour(provider)),
                        _buildQuickActionChip('Last 24 hours', () => _searchLastDay(provider)),
                        _buildQuickActionChip('Recent 100', () => _searchRecent100(provider)),
                        _buildQuickActionChip('All data', () => _searchAll(provider)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchTypeChip(String type, String label, IconData icon) {
    final isSelected = _searchType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _searchType = type;
          _searchController.clear();
          _fieldController.clear();
          _fieldName = '';
        });
      },
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: AppTheme.primaryBlue,
        width: 1,
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      elevation: 2,
    );
  }

  String _getFieldHint() {
    switch (_searchType) {
      case 'match':
        return 'title, content, message';
      case 'term':
        return 'status, category, user_id';
      case 'wildcard':
        return 'filename, path, name';
      default:
        return 'field_name';
    }
  }

  String _getSearchLabel() {
    switch (_searchType) {
      case 'match':
        return 'Search Text';
      case 'term':
        return 'Exact Value';
      case 'range':
        return 'Time Range';
      case 'wildcard':
        return 'Pattern';
      default:
        return 'Value';
    }
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'match':
        return 'Enter search terms...';
      case 'term':
        return 'exact_value';
      case 'range':
        return 'now-1h, now-1d, 2024-01-01';
      case 'wildcard':
        return 'test*, *log*, *error*';
      default:
        return 'Enter value...';
    }
  }

  bool _canSearch(ElasticsearchProvider provider) {
    if (!provider.isConnected || provider.selectedIndex == null || provider.isLoading) {
      return false;
    }
    
    // For match_all, no additional fields required
    if (_searchType == 'match_all') {
      return true;
    }
    
    // For range queries, only need search text (time range)
    if (_searchType == 'range') {
      return _searchController.text.isNotEmpty;
    }
    
    // For other search types, need both field name and search text
    return _fieldName.isNotEmpty && _searchController.text.isNotEmpty;
  }

  Future<void> _executeSearch(ElasticsearchProvider provider) async {
    try {
      print('Executing search with type: $_searchType, field: $_fieldName, query: ${_searchController.text}');
      
      // Verify connection before searching
      if (!provider.isConnected) {
        print('Connection not verified, attempting to reconnect...');
        final connected = await provider.verifyConnection();
        if (!connected) {
          throw Exception('Failed to connect to Elasticsearch. Please check your connection settings.');
        }
      }
      
      final query = _buildQuery();
      print('Built query: $query');
      
      final result = await provider.search(
        index: provider.selectedIndex!,
        query: query,
        size: _size,
        from: 0,
      );
      
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Found ${result.hits.total.value} results'),
                ],
              ),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Search returned no results'),
                ],
              ),
              backgroundColor: AppTheme.accentOrange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        String errorMessage = e.toString();
        Color errorColor = AppTheme.accentRed;
        
        // Provide specific error handling
        if (errorMessage.contains('Not connected')) {
          errorMessage = 'Connection lost. Please reconnect to Elasticsearch.';
        } else if (errorMessage.contains('401')) {
          errorMessage = 'Authentication failed. Please check your credentials.';
        } else if (errorMessage.contains('404')) {
          errorMessage = 'Index not found. Please select a valid index.';
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Request timeout. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _executeSearch(provider),
            ),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _buildQuery() {
    Map<String, dynamic> query;

    switch (_searchType) {
      case 'match_all':
        query = {'match_all': {}};
        break;
      case 'match':
        query = {
          'match': {
            _fieldName: _searchController.text,
          }
        };
        break;
      case 'term':
        query = {
          'term': {
            '$_fieldName.keyword': _searchController.text,
          }
        };
        break;
      case 'range':
        query = {
          'range': {
            _fieldName.isNotEmpty ? _fieldName : 'timestamp': {
              'gte': _searchController.text,
              'lte': 'now',
            }
          }
        };
        break;
      case 'wildcard':
        query = {
          'wildcard': {
            _fieldName: _searchController.text,
          }
        };
        break;
      default:
        query = {'match_all': {}};
    }

    final result = <String, dynamic>{
      'query': query,
    };

    // 只有当用户明确选择了排序字段时才添加排序
    if (_sortField.isNotEmpty) {
      result['sort'] = [
        {_sortField: {'order': _sortOrder}}
      ];
    }

    return result;
  }

  Future<void> _searchLastHour(ElasticsearchProvider provider) async {
    if (!_canSearchQuick(provider)) return;
    
    final query = {
      'query': {
        'range': {
          '@timestamp': {
            'gte': 'now-1h',
            'lte': 'now',
          }
        }
      },
      'sort': [
        {'@timestamp': {'order': 'desc'}}
      ],
    };

    await provider.search(
      index: provider.selectedIndex!,
      query: query,
      size: 100,
      from: 0,
    );
  }

  Future<void> _searchLastDay(ElasticsearchProvider provider) async {
    if (!_canSearchQuick(provider)) return;
    
    final query = {
      'query': {
        'range': {
          '@timestamp': {
            'gte': 'now-1d',
            'lte': 'now',
          }
        }
      },
      'sort': [
        {'@timestamp': {'order': 'desc'}}
      ],
    };

    await provider.search(
      index: provider.selectedIndex!,
      query: query,
      size: 100,
      from: 0,
    );
  }

  Future<void> _searchRecent100(ElasticsearchProvider provider) async {
    if (!_canSearchQuick(provider)) return;
    
    final query = {
      'query': {'match_all': {}},
      'sort': [
        {'@timestamp': {'order': 'desc'}}
      ],
    };

    await provider.search(
      index: provider.selectedIndex!,
      query: query,
      size: 100,
      from: 0,
    );
  }

  Future<void> _searchAll(ElasticsearchProvider provider) async {
    if (!_canSearchQuick(provider)) return;
    
    final query = {
      'query': {'match_all': {}},
      'sort': [
        {'@timestamp': {'order': 'desc'}}
      ],
    };

    await provider.search(
      index: provider.selectedIndex!,
      query: query,
      size: 1000,
      from: 0,
    );
  }

  bool _canSearchQuick(ElasticsearchProvider provider) {
    return provider.isConnected && 
           provider.selectedIndex != null && 
           !provider.isLoading;
  }
}