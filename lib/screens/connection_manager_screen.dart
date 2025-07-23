import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/elasticsearch_provider.dart';
import '../models/elasticsearch_config.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'connection_detail_screen.dart';
import 'index_list_screen.dart';  // 添加索引列表导入
import '../utils/safe_transform_utils.dart';

class ConnectionManagerScreen extends StatefulWidget {
  const ConnectionManagerScreen({super.key});

  @override
  State<ConnectionManagerScreen> createState() => _ConnectionManagerScreenState();
}

class _ConnectionManagerScreenState extends State<ConnectionManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved connections when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ElasticsearchProvider>().loadSavedConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Elasticsearch Connections',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddConnectionDialog(context),
            tooltip: 'Add New Connection',
          ),
        ],
      ),
      body: Consumer<ElasticsearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.savedConfigs.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildConnectionsList(context, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // 添加这个限制
        children: [
          Icon(
            Icons.storage_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'No Connections Saved',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first Elasticsearch connection to get started',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddConnectionDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Connection'),
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

  Widget _buildConnectionsList(BuildContext context, ElasticsearchProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.savedConfigs.length,
      itemBuilder: (context, index) {
        final config = provider.savedConfigs[index];
        return _buildConnectionCard(context, config, provider);
      },
    );
  }

  Widget _buildConnectionCard(BuildContext context, ElasticsearchConfig config, ElasticsearchProvider provider) {
    final isCurrentConnection = provider.config?.host == config.host && 
                               provider.config?.port == config.port;
    
    return UltraSafeWidget(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentConnection 
              ? BorderSide(color: AppTheme.primaryBlue, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _connectToElasticsearch(context, config, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 添加这个限制
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.storage_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // 添加这个限制
                        children: [
                          Text(
                            config.name.isNotEmpty ? config.name : '${config.host}:${config.port}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${config.host}:${config.port}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentConnection) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Connected',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value, config, provider),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'test',
                          child: Row(
                            children: [
                              Icon(Icons.wifi_tethering_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Test Connection'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip('Version', config.version),
                    const SizedBox(width: 8),
                    if (config.username != null && config.username!.isNotEmpty)
                      _buildInfoChip('Auth', 'Basic'),
                    if (config.apiKey != null && config.apiKey!.isNotEmpty)
                      _buildInfoChip('Auth', 'API Key'),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons row
                if (isCurrentConnection) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const IndexListScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_rounded, size: 16),
                          label: const Text('View Indices'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: BorderSide(color: AppTheme.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Search'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: BorderSide(color: AppTheme.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _connectToElasticsearch(context, config, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentConnection ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isCurrentConnection ? 'Connected' : 'Connect & Search',
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

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  void _showAddConnectionDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConnectionDetailScreen(),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, ElasticsearchConfig config, ElasticsearchProvider provider) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConnectionDetailScreen(config: config),
          ),
        );
        break;
      case 'test':
        _testConnection(context, config, provider);
        break;
      case 'delete':
        _showDeleteConfirmation(context, config, provider);
        break;
    }
  }

  void _testConnection(BuildContext context, ElasticsearchConfig config, ElasticsearchProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    try {
      await provider.setConfig(config);
      final success = await provider.testConnection();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(success ? 'Success' : 'Failed'),
              ],
            ),
            content: Text(
              success 
                  ? 'Connection to Elasticsearch successful!'
                  : provider.error ?? 'Connection failed',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Connection test failed: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, ElasticsearchConfig config, ElasticsearchProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete the connection to ${config.host}:${config.port}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeSavedConfig(config);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connection deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _connectToElasticsearch(BuildContext context, ElasticsearchConfig config, ElasticsearchProvider provider) async {
    // If already connected to this config, go directly to search
    if (provider.config?.host == config.host && 
        provider.config?.port == config.port && 
        provider.isConnected) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      );
      return;
    }

    // Show loading with timeout warning and cancel button
    bool cancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Connecting...'),
            const SizedBox(height: 8),
            Text(
              'Connecting to ${config.host}:${config.port}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This may take up to 15 seconds',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    try {
      // Set config first
      await provider.setConfig(config);
      
      // Add explicit timeout and better error handling
      final success = await provider.testConnection().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timeout after 15 seconds', const Duration(seconds: 15));
        },
      );
      
      if (context.mounted && !cancelled) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (success) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
        } else {
          _showConnectionError(context, provider.error ?? 'Unable to connect to Elasticsearch');
        }
      }
    } on TimeoutException catch (e) {
      if (context.mounted && !cancelled) {
        Navigator.of(context).pop(); // Close loading dialog
        _showConnectionError(context, 'Connection timeout: ${e.message}\n\nPlease check:\n• Elasticsearch is running\n• Host and port are correct\n• Network connectivity');
      }
    } catch (e) {
      if (context.mounted && !cancelled) {
        Navigator.of(context).pop(); // Close loading dialog
        _showConnectionError(context, 'Connection failed: $e');
      }
    }
  }

  void _showConnectionError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Connection Failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}