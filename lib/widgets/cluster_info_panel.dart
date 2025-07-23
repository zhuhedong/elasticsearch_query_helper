import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/elasticsearch_provider.dart';
import '../utils/safe_transform_utils.dart';

class ClusterInfoPanel extends StatefulWidget {
  const ClusterInfoPanel({super.key});

  @override
  State<ClusterInfoPanel> createState() => _ClusterInfoPanelState();
}

class _ClusterInfoPanelState extends State<ClusterInfoPanel> {
  String _selectedIndex = '';
  Map<String, dynamic>? _indexMapping;

  @override
  Widget build(BuildContext context) {
    return Consumer<ElasticsearchProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) {
          return _buildNotConnectedState();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cluster Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    // Left Panel - Cluster Health & Indices
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildClusterHealthCard(provider),
                          const SizedBox(height: 16),
                          Expanded(child: _buildIndicesCard(provider)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Panel - Index Details
                    Expanded(
                      flex: 1,
                      child: _buildIndexDetailsCard(provider),
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

  Widget _buildNotConnectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Not Connected',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to Elasticsearch to view cluster information.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterHealthCard(ElasticsearchProvider provider) {
    final health = provider.clusterHealth;
    if (health == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final status = health['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cluster Health',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Cluster Name',
                    health['cluster_name']?.toString() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Nodes',
                    health['number_of_nodes']?.toString() ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Data Nodes',
                    health['number_of_data_nodes']?.toString() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Active Shards',
                    health['active_shards']?.toString() ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Relocating Shards',
                    health['relocating_shards']?.toString() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Unassigned Shards',
                    health['unassigned_shards']?.toString() ?? 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildIndicesCard(ElasticsearchProvider provider) {
    final indices = provider.indices;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Indices (${indices.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copyIndicesToClipboard(indices),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy indices list',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: indices.length,
                itemBuilder: (context, index) {
                  final indexInfo = indices[index];
                  final indexName = indexInfo['index'] ?? 'unknown';
                  final isSelected = _selectedIndex == indexName;
                  
                  return UltraSafeWidget(
                    child: Card(
                      elevation: isSelected ? 2 : 0,
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                      child: ListTile(
                        title: Text(indexName),
                        subtitle: Row(
                          children: [
                            Text('Health: ${indexInfo['health'] ?? 'N/A'}'),
                            const SizedBox(width: 16),
                            Text('Docs: ${indexInfo['docs.count'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Text(
                          indexInfo['store.size'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _loadIndexMapping(provider, indexName),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexDetailsCard(ElasticsearchProvider provider) {
    if (_selectedIndex.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Index Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select an index to view its mapping and details.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Index: $_selectedIndex',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyMappingToClipboard(),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy mapping',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_indexMapping != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapping',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(_indexMapping!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Failed to load mapping'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadIndexMapping(ElasticsearchProvider provider, String indexName) async {
    setState(() {
      _selectedIndex = indexName;
      _indexMapping = null;
    });

    final mapping = await provider.getMapping(indexName);
    if (mounted) {
      setState(() {
        _indexMapping = mapping;
      });
    }
  }

  Future<void> _copyIndicesToClipboard(List<Map<String, dynamic>> indices) async {
    final indicesJson = const JsonEncoder.withIndent('  ').convert(indices);
    await Clipboard.setData(ClipboardData(text: indicesJson));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indices list copied to clipboard')),
      );
    }
  }

  Future<void> _copyMappingToClipboard() async {
    if (_indexMapping == null) return;
    
    final mappingJson = const JsonEncoder.withIndent('  ').convert(_indexMapping!);
    await Clipboard.setData(ClipboardData(text: mappingJson));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mapping copied to clipboard')),
      );
    }
  }
}