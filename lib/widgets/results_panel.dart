import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/elasticsearch_provider.dart';
import '../models/search_result.dart';

class ResultsPanel extends StatefulWidget {
  const ResultsPanel({super.key});

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
  String _selectedView = 'table';
  bool _showMetadata = true;
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<ElasticsearchProvider>(
      builder: (context, provider, child) {
        if (provider.lastSearchResult == null) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider.lastSearchResult!),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
              Expanded(child: _buildResultsView(provider.lastSearchResult!)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Search Results',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Execute a query to see results here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SearchResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Query Results',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricChip(
                        'Total Hits',
                        result.hits.total.value.toString(),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        'Returned',
                        result.hits.hits.length.toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        'Time',
                        '${result.took}ms',
                        Colors.orange,
                      ),
                      if (result.hits.maxScore != null) ...[
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          'Max Score',
                          result.hits.maxScore?.toStringAsFixed(3) ?? 'N/A',
                          Colors.purple,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _copyToClipboard(result),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy raw response',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              'View:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'table',
                  label: Text('Table'),
                  icon: Icon(Icons.table_chart),
                ),
                ButtonSegment(
                  value: 'json',
                  label: Text('JSON'),
                  icon: Icon(Icons.code),
                ),
                ButtonSegment(
                  value: 'cards',
                  label: Text('Cards'),
                  icon: Icon(Icons.view_agenda),
                ),
              ],
              selected: {_selectedView},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedView = selection.first;
                });
              },
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Checkbox(
                  value: _showMetadata,
                  onChanged: (value) {
                    setState(() {
                      _showMetadata = value!;
                    });
                  },
                ),
                const Text('Show Metadata'),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Filter results...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchFilter = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(SearchResult result) {
    final filteredHits = _filterHits(result.hits.hits);

    switch (_selectedView) {
      case 'table':
        return _buildTableView(filteredHits);
      case 'json':
        return _buildJsonView(filteredHits);
      case 'cards':
        return _buildCardsView(filteredHits);
      default:
        return _buildTableView(filteredHits);
    }
  }

  List<SearchHit> _filterHits(List<SearchHit> hits) {
    if (_searchFilter.isEmpty) return hits;
    
    return hits.where((hit) {
      final sourceStr = json.encode(hit.source).toLowerCase();
      return sourceStr.contains(_searchFilter.toLowerCase()) ||
             hit.index.toLowerCase().contains(_searchFilter.toLowerCase()) ||
             hit.id.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();
  }

  Widget _buildTableView(List<SearchHit> hits) {
    if (hits.isEmpty) {
      return const Center(child: Text('No results match the filter.'));
    }

    // Get all unique keys from all documents
    final allKeys = <String>{};
    for (final hit in hits) {
      allKeys.addAll(hit.source.keys);
    }
    final sortedKeys = allKeys.toList()..sort();

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              columns: [
                if (_showMetadata) ...[
                  const DataColumn(label: Text('Index')),
                  const DataColumn(label: Text('ID')),
                  const DataColumn(label: Text('Score')),
                ],
                ...sortedKeys.map((key) => DataColumn(label: Text(key))),
              ],
              rows: hits.map((hit) {
                return DataRow(
                  cells: [
                    if (_showMetadata) ...[
                      DataCell(Text(hit.index)),
                      DataCell(Text(hit.id)),
                      DataCell(Text(hit.score?.toStringAsFixed(3) ?? 'N/A')),
                    ],
                    ...sortedKeys.map((key) {
                      final value = hit.source[key];
                      return DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            _formatValue(value),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJsonView(List<SearchHit> hits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: hits.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final hit = hits[index];
            return ExpansionTile(
              title: Text('Document ${index + 1}'),
              subtitle: _showMetadata
                  ? Text('${hit.index}/${hit.id} (Score: ${hit.score?.toStringAsFixed(3) ?? 'N/A'})')
                  : null,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey.shade50,
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(hit.source),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardsView(List<SearchHit> hits) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: hits.length,
      itemBuilder: (context, index) {
        final hit = hits[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showMetadata) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hit.index,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hit.score != null)
                        Chip(
                          label: Text(hit.score?.toStringAsFixed(2) ?? 'N/A'),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  Text(
                    'ID: ${hit.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: hit.source.entries.take(5).map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${entry.key}:',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatValue(entry.value),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List) return '[${value.length} items]';
    if (value is Map) return '{${value.length} fields}';
    return value.toString();
  }

  Future<void> _copyToClipboard(SearchResult result) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(result.toJson());
    await Clipboard.setData(ClipboardData(text: jsonString));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response copied to clipboard')),
      );
    }
  }
}