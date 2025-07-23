import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../theme/app_theme.dart';
import '../utils/safe_transform_utils.dart';

class IndexSelector extends StatefulWidget {
  final Function(String)? onIndexSelected;
  
  const IndexSelector({
    super.key,
    this.onIndexSelected,
  });

  @override
  State<IndexSelector> createState() => _IndexSelectorState();
}

class _IndexSelectorState extends State<IndexSelector> {
  String _searchQuery = '';
  bool _showSystemIndices = false;

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
            mainAxisSize: MainAxisSize.min, // 关键修复：限制Column的主轴大小
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (provider.isConnected) ...[
                      Text(
                        '${_getFilteredIndices(provider).length} indices',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => provider.loadIndices(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Refresh indices',
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content area with fixed height
              SizedBox(
                height: 300, // 固定高度，避免无界约束
                child: _buildContent(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ElasticsearchProvider provider) {
    if (!provider.isConnected) {
      return _buildNotConnectedState();
    } else if (provider.isLoading) {
      return _buildLoadingState();
    } else {
      return Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search indices...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Checkbox(
                            value: _showSystemIndices,
                            onChanged: (value) {
                              setState(() {
                                _showSystemIndices = value ?? false;
                              });
                            },
                          ),
                          const Text('Show system indices'),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _selectAllIndices(provider),
                      icon: const Icon(Icons.select_all_rounded, size: 16),
                      label: const Text('All'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indices list
          Expanded(
            child: _buildIndicesList(provider),
          ),
        ],
      );
    }
  }

  Widget _buildNotConnectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Not Connected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to Elasticsearch to view indices',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading indices...'),
        ],
      ),
    );
  }

  Widget _buildIndicesList(ElasticsearchProvider provider) {
    final filteredIndices = _getFilteredIndices(provider);
    
    if (filteredIndices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No matching indices' : 'No indices found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredIndices.length,
      itemBuilder: (context, index) {
        final indexData = filteredIndices[index];
        final indexName = indexData['index'] as String;
        final isSelected = provider.selectedIndex == indexName;
        final isSystemIndex = indexName.startsWith('.');
        
        return UltraSafeWidget(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryBlue
                    : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => _selectIndex(provider, indexName),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSystemIndex 
                      ? AppTheme.accentOrange.withOpacity(0.1)
                      : AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSystemIndex 
                      ? Icons.settings_rounded
                      : Icons.storage_rounded,
                  size: 16,
                  color: isSystemIndex 
                      ? AppTheme.accentOrange
                      : AppTheme.accentGreen,
                ),
              ),
              title: Text(
                indexName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                ),
              ),
              subtitle: _buildIndexSubtitle(indexData),
              trailing: isSelected 
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndexSubtitle(Map<String, dynamic> indexData) {
    final docsCount = indexData['docs.count'] ?? '0';
    final storeSize = indexData['store.size'] ?? '0b';
    
    return Row(
      children: [
        Icon(
          Icons.description_rounded,
          size: 12,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          '$docsCount docs',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.storage_rounded,
          size: 12,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          storeSize,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredIndices(ElasticsearchProvider provider) {
    var indices = provider.indices;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      indices = indices.where((index) {
        final indexName = index['index'] as String;
        return indexName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filter system indices
    if (!_showSystemIndices) {
      indices = indices.where((index) {
        final indexName = index['index'] as String;
        return !indexName.startsWith('.');
      }).toList();
    }
    
    // Sort by name
    indices.sort((a, b) {
      final nameA = a['index'] as String;
      final nameB = b['index'] as String;
      return nameA.compareTo(nameB);
    });
    
    return indices;
  }

  void _selectIndex(ElasticsearchProvider provider, String indexName) {
    provider.setSelectedIndex(indexName);
    widget.onIndexSelected?.call(indexName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Selected index: $indexName'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectAllIndices(ElasticsearchProvider provider) {
    provider.setSelectedIndex('*');
    widget.onIndexSelected?.call('*');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.select_all_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Selected all indices'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}