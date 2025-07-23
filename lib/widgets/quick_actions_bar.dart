import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../theme/app_theme.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ElasticsearchProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Connection status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: provider.isConnected 
                      ? AppTheme.accentGreen.withOpacity(0.1)
                      : AppTheme.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: provider.isConnected 
                        ? AppTheme.accentGreen
                        : AppTheme.accentRed,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isConnected 
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      size: 16,
                      color: provider.isConnected 
                          ? AppTheme.accentGreen
                          : AppTheme.accentRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: provider.isConnected 
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (provider.isConnected && provider.config != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${provider.config!.host}:${provider.config!.port}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Quick action buttons
              if (provider.isConnected) ...[
                _buildQuickActionButton(
                  context,
                  'Match All',
                  Icons.select_all_rounded,
                  AppTheme.accentGreen,
                  () => _executeQuickQuery(context, provider, {
                    'query': {'match_all': {}},
                    'size': 10
                  }),
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  context,
                  'Cluster Info',
                  Icons.info_rounded,
                  AppTheme.accentTeal,
                  () => _getClusterInfo(context, provider),
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  context,
                  'Indices',
                  Icons.list_rounded,
                  AppTheme.accentOrange,
                  () => _listIndices(context, provider),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _showQuickConnect(context),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('Quick Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _executeQuickQuery(
    BuildContext context,
    ElasticsearchProvider provider,
    Map<String, dynamic> query,
  ) async {
    try {
      await provider.search(
        index: '*',
        query: query,
        size: 10,
        from: 0,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Query executed successfully'),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Query failed: $e')),
              ],
            ),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _getClusterInfo(
    BuildContext context,
    ElasticsearchProvider provider,
  ) async {
    try {
      // Use existing cluster health data or test connection to refresh it
      if (provider.clusterHealth == null) {
        await provider.testConnection();
      }
      
      if (context.mounted) {
        final health = provider.clusterHealth;
        if (health != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cluster Information'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Cluster Name', health['cluster_name'] ?? 'Unknown'),
                  _buildInfoRow('Status', health['status'] ?? 'Unknown'),
                  _buildInfoRow('Nodes', '${health['number_of_nodes'] ?? 0}'),
                  _buildInfoRow('Data Nodes', '${health['number_of_data_nodes'] ?? 0}'),
                  _buildInfoRow('Active Shards', '${health['active_shards'] ?? 0}'),
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No cluster information available'),
              backgroundColor: AppTheme.accentOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get cluster info: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _listIndices(
    BuildContext context,
    ElasticsearchProvider provider,
  ) async {
    try {
      // This would need to be implemented in the provider
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indices list feature coming soon!'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to list indices: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showQuickConnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Quick Connect',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // This would contain the QuickConnectWidget
              const Text(
                'Use the Quick Connect feature in the Connection tab to get started quickly.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go to Connection Tab'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}