import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/elasticsearch_provider.dart';
import '../widgets/query_shortcuts.dart';

class QueryPanel extends StatefulWidget {
  const QueryPanel({super.key});

  @override
  State<QueryPanel> createState() => _QueryPanelState();
}

class _QueryPanelState extends State<QueryPanel> {
  final _queryController = TextEditingController();
  final _indexController = TextEditingController();
  final _sizeController = TextEditingController(text: '10');
  final _fromController = TextEditingController(text: '0');
  
  String _selectedQueryMode = 'builder';
  bool _prettifyJson = true;

  @override
  void dispose() {
    _queryController.dispose();
    _indexController.dispose();
    _sizeController.dispose();
    _fromController.dispose();
    super.dispose();
  }

  void _insertTemplate(Map<String, dynamic> template) {
    final prettyJson = _prettifyJson 
        ? const JsonEncoder.withIndent('  ').convert(template)
        : json.encode(template);
    _queryController.text = prettyJson;
  }

  void _prettifyQuery() {
    try {
      final queryText = _queryController.text.trim();
      if (queryText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Query is empty')),
          );
        }
        return;
      }
      
      final queryJson = json.decode(queryText);
      final prettyQuery = const JsonEncoder.withIndent('  ').convert(queryJson);
      _queryController.text = prettyQuery;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _executeQuery() async {
    final provider = Provider.of<ElasticsearchProvider>(context, listen: false);
    
    if (!provider.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected to Elasticsearch')),
        );
      }
      return;
    }

    String index = _indexController.text.trim();
    if (index.isEmpty) {
      index = provider.config?.indexPattern ?? '*';
    }

    try {
      final queryText = _queryController.text.trim();
      if (queryText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Query cannot be empty')),
          );
        }
        return;
      }

      final queryJson = json.decode(queryText);
      final size = int.tryParse(_sizeController.text) ?? 10;
      final from = int.tryParse(_fromController.text) ?? 0;

      await provider.search(
        index: index,
        query: queryJson,
        size: size,
        from: from,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Query executed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Query error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElasticsearchProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Query Builder',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Query Mode Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Query Mode:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'builder',
                            label: Text('Builder'),
                            icon: Icon(Icons.build),
                          ),
                          ButtonSegment(
                            value: 'raw',
                            label: Text('Raw JSON'),
                            icon: Icon(Icons.code),
                          ),
                        ],
                        selected: {_selectedQueryMode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedQueryMode = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Query Shortcuts
              QueryShortcuts(
                queryController: _queryController,
                onQueryInserted: (query) {
                  setState(() {
                    _selectedQueryMode = 'raw';
                  });
                },
              ),

              // Templates Section
              if (provider.isConnected && _selectedQueryMode == 'raw') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Query Templates (${provider.config?.version})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: provider.getQueryTemplates()
                              .map((template) => FilterChip(
                                    label: Text(template.name),
                                    tooltip: template.description,
                                    onSelected: (_) => _insertTemplate(template.query),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Query Parameters
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Query Parameters',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _indexController,
                              decoration: InputDecoration(
                                labelText: 'Index Pattern',
                                hintText: provider.config?.indexPattern ?? '*',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sizeController,
                              decoration: const InputDecoration(
                                labelText: 'Size',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _fromController,
                              decoration: const InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Query Editor
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedQueryMode == 'builder' ? 'Visual Query Builder' : 'JSON Query',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (_selectedQueryMode == 'raw') ...[
                              Row(
                                children: [
                                  Checkbox(
                                    value: _prettifyJson,
                                    onChanged: (value) {
                                      setState(() {
                                        _prettifyJson = value!;
                                      });
                                    },
                                  ),
                                  const Text('Pretty JSON'),
                                ],
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _prettifyQuery,
                                icon: const Icon(Icons.format_align_left),
                                label: const Text('Format'),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _selectedQueryMode == 'builder'
                              ? _buildVisualQueryBuilder(context, provider)
                              : _buildJsonQueryEditor(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Execute Button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isConnected && !provider.isLoading 
                      ? _executeQuery 
                      : null,
                  icon: provider.isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(provider.isLoading ? 'Executing...' : 'Execute Query'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJsonQueryEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _queryController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'Enter your Elasticsearch query in JSON format...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildVisualQueryBuilder(BuildContext context, ElasticsearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Visual Query Builder',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Build queries visually with drag-and-drop interface',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Quick Actions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionButton(
                context,
                'Match All',
                Icons.select_all,
                () => _insertQuickQuery(context, {
                  'query': {'match_all': {}}
                }),
              ),
              _buildQuickActionButton(
                context,
                'Term Query',
                Icons.search,
                () => _insertQuickQuery(context, {
                  'query': {
                    'term': {
                      'field_name': 'value'
                    }
                  }
                }),
              ),
              _buildQuickActionButton(
                context,
                'Range Query',
                Icons.tune,
                () => _insertQuickQuery(context, {
                  'query': {
                    'range': {
                      'date_field': {
                        'gte': 'now-1d',
                        'lte': 'now'
                      }
                    }
                  }
                }),
              ),
              _buildQuickActionButton(
                context,
                'Bool Query',
                Icons.merge_type,
                () => _insertQuickQuery(context, {
                  'query': {
                    'bool': {
                      'must': [
                        {'match': {'field1': 'value1'}}
                      ],
                      'filter': [
                        {'term': {'field2': 'value2'}}
                      ]
                    }
                  }
                }),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedQueryMode = 'raw';
                    _queryController.text = const JsonEncoder.withIndent('  ').convert({
                      'query': {
                        'match_all': {}
                      }
                    });
                  });
                },
                icon: const Icon(Icons.code),
                label: const Text('Switch to JSON Editor'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visual builder coming in next update!'),
                    ),
                  );
                },
                icon: const Icon(Icons.construction),
                label: const Text('Coming Soon'),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _insertQuickQuery(BuildContext context, Map<String, dynamic> query) {
    setState(() {
      _selectedQueryMode = 'raw';
      _queryController.text = const JsonEncoder.withIndent('  ').convert(query);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${query['query'].keys.first} query template inserted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}