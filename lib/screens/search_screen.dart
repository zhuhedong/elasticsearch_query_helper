import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../widgets/index_selector.dart';
import '../widgets/quick_search_panel.dart';
import '../theme/app_theme.dart';
import 'connection_manager_screen.dart';
import 'index_list_screen.dart';  // 添加索引列表导入

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
              mainAxisSize: MainAxisSize.min, // 添加这个限制
              children: [
                const Text(
                  'Elasticsearch Search',
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
          IconButton(
            icon: const Icon(Icons.list_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IndexListScreen(),
                ),
              );
            },
            tooltip: 'View All Indices',
          ),
          IconButton(
            icon: const Icon(Icons.storage_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionManagerScreen(),
                ),
              );
            },
            tooltip: 'Manage Connections',
          ),
          Consumer<ElasticsearchProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected 
                      ? Theme.of(context).colorScheme.secondary 
                      : Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _showConnectionStatus(context, provider),
                tooltip: 'Connection Status',
              );
            },
          ),
        ],
      ),
      body: Consumer<ElasticsearchProvider>(
        builder: (context, provider, child) {
          if (!provider.isConnected) {
            return _buildNotConnectedState(context);
          }

          // 使用更安全的布局结构
          return SafeArea(
            child: Column(
              children: [
                // Index Selection Section - 固定高度
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: const IndexSelector(),
                ),
                
                // Search Section - 使用Expanded确保剩余空间被正确分配
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 限制Column大小
                      children: [
                        const QuickSearchPanel(),
                        const SizedBox(height: 24),
                        _buildSearchResults(context, provider),
                      ],
                    ),
                  ),
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
        mainAxisSize: MainAxisSize.min, // 添加这个限制
        children: [
          Icon(
            Icons.wifi_off,
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
            'Please connect to an Elasticsearch instance to start searching',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ConnectionManagerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.storage_outlined),
            label: const Text('Manage Connections'),
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

  Widget _buildSearchResults(BuildContext context, ElasticsearchProvider provider) {
    if (provider.isLoading) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: const Column(
            mainAxisSize: MainAxisSize.min, // 限制Column大小
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Searching...'),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 限制Column大小
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Search Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  provider.clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Clear Error'),
              ),
            ],
          ),
        ),
      );
    }

    final searchResult = provider.lastSearchResult;
    if (searchResult == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 限制Column大小
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an index and choose a search type to get started',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 限制Column大小
          children: [
            Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${searchResult.hits.total.value} results',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search metadata
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildMetadataItem('Took', '${searchResult.took ?? 0}ms'),
                  const SizedBox(width: 16),
                  _buildMetadataItem('Total', '${searchResult.hits.total.value}'),
                  const SizedBox(width: 16),
                  _buildMetadataItem('Showing', '${searchResult.hits.hits.length}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results list
            if (searchResult.hits.hits.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 限制Column大小
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Results Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search criteria',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              )
            else
              ...searchResult.hits.hits.map((hit) => _buildResultItem(hit)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // 限制Column大小
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(dynamic hit) {
    final source = hit.source as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 限制Column大小
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hit.index,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${hit.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              if (hit.score != null)
                Text(
                  'Score: ${hit.score!.toStringAsFixed(3)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...source.entries.take(5).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}'.length > 100 
                        ? '${entry.value}'.substring(0, 100) + '...'
                        : '${entry.value}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
          if (source.length > 5) ...[
            const SizedBox(height: 4),
            Text(
              '... and ${source.length - 5} more fields',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
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
              color: provider.isConnected 
                  ? Theme.of(context).colorScheme.secondary 
                  : Theme.of(context).colorScheme.error,
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