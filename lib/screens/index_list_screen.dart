import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../theme/app_theme.dart';
import '../utils/safe_transform_utils.dart';

class IndexListScreen extends StatefulWidget {
  const IndexListScreen({super.key});

  @override
  State<IndexListScreen> createState() => _IndexListScreenState();
}

class _IndexListScreenState extends State<IndexListScreen> {
  String _searchQuery = '';
  bool _showSystemIndices = false;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Load indices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ElasticsearchProvider>();
      if (provider.isConnected) {
        provider.loadIndices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Consumer<ElasticsearchProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Elasticsearch Indices',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                if (provider.config != null)
                  Text(
                    '${provider.config!.host}:${provider.config!.port}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        actions: [
          Consumer<ElasticsearchProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () => _showConnectionStatus(context, provider),
                tooltip: 'Connection Status',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final provider = context.read<ElasticsearchProvider>();
              if (provider.isConnected) {
                provider.loadIndices();
              }
            },
            tooltip: 'Refresh Indices',
          ),
        ],
      ),
      body: Consumer<ElasticsearchProvider>(
        builder: (context, provider, child) {
          if (!provider.isConnected) {
            return _buildNotConnectedState(context);
          }

          return SafeArea(
            child: Column(
              children: [
                // Search and Filter Section
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchAndFilters(),
                ),
                
                // Indices List
                Expanded(
                  child: _buildIndicesList(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotConnectedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'Not Connected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please connect to an Elasticsearch instance to view indices',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
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
        
        // Filters and sort
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
            DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                DropdownMenuItem(value: 'docs', child: Text('Sort by Docs')),
                DropdownMenuItem(value: 'size', child: Text('Sort by Size')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? 'name';
                });
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
              tooltip: _sortAscending ? 'Ascending' : 'Descending',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicesList(ElasticsearchProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading indices...'),
          ],
        ),
      );
    }

    // Show error if there is one
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Indices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
                if (provider.isConnected) {
                  provider.loadIndices();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final filteredIndices = _getFilteredAndSortedIndices(provider);
    
    if (filteredIndices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
      padding: const EdgeInsets.all(16),
      itemCount: filteredIndices.length,
      itemBuilder: (context, index) {
        final indexData = filteredIndices[index];
        return _buildIndexCard(indexData, provider);
      },
    );
  }

  Widget _buildIndexCard(Map<String, dynamic> indexData, ElasticsearchProvider provider) {
    final indexName = indexData['index'] as String;
    final isSelected = provider.selectedIndex == indexName;
    final isSystemIndex = indexName.startsWith('.');
    final docsCount = indexData['docs.count'] ?? '0';
    final storeSize = indexData['store.size'] ?? '0b';
    final health = indexData['health'] ?? 'unknown';
    final status = indexData['status'] ?? 'unknown';
    
    return UltraSafeWidget(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectIndex(provider, indexName),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
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
                        size: 20,
                        color: isSystemIndex 
                            ? AppTheme.accentOrange
                            : AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            indexName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatusChip(health),
                              const SizedBox(width: 8),
                              _buildStatusChip(status, isStatus: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Statistics row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('Documents', docsCount, Icons.description_rounded),
                    ),
                    Expanded(
                      child: _buildStatItem('Size', storeSize, Icons.storage_rounded),
                    ),
                    Expanded(
                      child: _buildStatItem('Shards', indexData['pri'] ?? '0', Icons.grain_rounded),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectIndex(provider, indexName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Select Index',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool isStatus = false}) {
    Color color;
    switch (status.toLowerCase()) {
      case 'green':
        color = AppTheme.accentGreen;
        break;
      case 'yellow':
        color = AppTheme.accentOrange;
        break;
      case 'red':
        color = AppTheme.accentRed;
        break;
      case 'open':
        color = AppTheme.accentGreen;
        break;
      case 'close':
        color = AppTheme.accentRed;
        break;
      default:
        color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textTertiary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredAndSortedIndices(ElasticsearchProvider provider) {
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
    
    // Sort indices
    indices.sort((a, b) {
      dynamic valueA, valueB;
      
      switch (_sortBy) {
        case 'docs':
          valueA = int.tryParse(a['docs.count']?.toString() ?? '0') ?? 0;
          valueB = int.tryParse(b['docs.count']?.toString() ?? '0') ?? 0;
          break;
        case 'size':
          valueA = a['store.size']?.toString() ?? '';
          valueB = b['store.size']?.toString() ?? '';
          break;
        default: // name
          valueA = a['index'] as String;
          valueB = b['index'] as String;
      }
      
      final comparison = _sortBy == 'docs' 
          ? (valueA as int).compareTo(valueB as int)
          : (valueA as String).compareTo(valueB as String);
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return indices;
  }

  void _selectIndex(ElasticsearchProvider provider, String indexName) {
    provider.setSelectedIndex(indexName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 16),
            const SizedBox(width: 8),
            Text('Selected index: $indexName'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConnectionStatus(BuildContext context, ElasticsearchProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              provider.isConnected ? Icons.wifi : Icons.wifi_off,
              color: provider.isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(provider.isConnected ? 'Connected' : 'Disconnected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.config != null) ...[
              Text('Host: ${provider.config!.host}'),
              Text('Port: ${provider.config!.port}'),
              Text('Version: ${provider.config!.version}'),
              if (provider.clusterHealth != null) ...[
                const SizedBox(height: 8),
                Text('Cluster: ${provider.clusterHealth!['cluster_name'] ?? 'Unknown'}'),
                Text('Status: ${provider.clusterHealth!['status'] ?? 'Unknown'}'),
              ],
            ] else
              const Text('No connection configured'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}