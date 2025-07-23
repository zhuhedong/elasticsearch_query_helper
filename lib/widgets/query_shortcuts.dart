import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/safe_transform_utils.dart';

class QueryShortcuts extends StatelessWidget {
  final TextEditingController queryController;
  final Function(String) onQueryInserted;

  const QueryShortcuts({
    super.key,
    required this.queryController,
    required this.onQueryInserted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Queries',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showQueryLibrary(context),
                icon: const Icon(Icons.library_books_rounded, size: 16),
                label: const Text('More'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickQueryButton(
                context,
                'All Documents',
                Icons.select_all_rounded,
                AppTheme.accentGreen,
                () => _insertQuery({
                  'query': {'match_all': {}},
                  'size': 10
                }),
              ),
              _buildQuickQueryButton(
                context,
                'Search Text',
                Icons.search_rounded,
                AppTheme.accentTeal,
                () => _insertQuery({
                  'query': {
                    'multi_match': {
                      'query': 'search_term',
                      'fields': ['title', 'content', 'description']
                    }
                  }
                }),
              ),
              _buildQuickQueryButton(
                context,
                'Date Range',
                Icons.date_range_rounded,
                AppTheme.accentOrange,
                () => _insertQuery({
                  'query': {
                    'range': {
                      '@timestamp': {
                        'gte': 'now-1d',
                        'lte': 'now'
                      }
                    }
                  }
                }),
              ),
              _buildQuickQueryButton(
                context,
                'Filter & Sort',
                Icons.filter_list_rounded,
                AppTheme.primaryBlueDark,
                () => _insertQuery({
                  'query': {
                    'bool': {
                      'filter': [
                        {'term': {'status': 'active'}}
                      ]
                    }
                  },
                  'sort': [
                    {'@timestamp': {'order': 'desc'}}
                  ]
                }),
              ),
              _buildQuickQueryButton(
                context,
                'Aggregation',
                Icons.analytics_rounded,
                AppTheme.accentPurple,
                () => _insertQuery({
                  'size': 0,
                  'aggs': {
                    'status_count': {
                      'terms': {
                        'field': 'status.keyword',
                        'size': 10
                      }
                    }
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _formatQuery(),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: const Text('Format JSON'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _validateQuery(context),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Validate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearQuery(),
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQueryButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _insertQuery(Map<String, dynamic> query) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(query);
    queryController.text = prettyJson;
    onQueryInserted(prettyJson);
  }

  void _formatQuery() {
    try {
      final text = queryController.text.trim();
      if (text.isEmpty) return;
      
      final queryJson = json.decode(text);
      final prettyQuery = const JsonEncoder.withIndent('  ').convert(queryJson);
      queryController.text = prettyQuery;
    } catch (e) {
      // Silently fail formatting
    }
  }

  void _validateQuery(BuildContext context) {
    try {
      final text = queryController.text.trim();
      if (text.isEmpty) {
        _showMessage(context, 'Query is empty', AppTheme.accentOrange);
        return;
      }
      
      json.decode(text);
      _showMessage(context, 'Query JSON is valid', AppTheme.accentGreen);
    } catch (e) {
      _showMessage(context, 'Invalid JSON: ${e.toString()}', AppTheme.accentRed);
    }
  }

  void _clearQuery() {
    queryController.clear();
  }

  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQueryLibrary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const QueryLibraryDialog(),
    );
  }
}

class QueryLibraryDialog extends StatelessWidget {
  const QueryLibraryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final queries = [
      {
        'name': 'Full Text Search',
        'description': 'Search across multiple fields with boosting',
        'query': {
          'query': {
            'multi_match': {
              'query': 'search term',
              'fields': ['title^2', 'content', 'tags'],
              'type': 'best_fields',
              'fuzziness': 'AUTO'
            }
          }
        }
      },
      {
        'name': 'Complex Boolean Query',
        'description': 'Combine multiple conditions with boolean logic',
        'query': {
          'query': {
            'bool': {
              'must': [
                {'match': {'status': 'published'}}
              ],
              'filter': [
                {'range': {'publish_date': {'gte': 'now-30d'}}}
              ],
              'must_not': [
                {'term': {'category': 'draft'}}
              ],
              'should': [
                {'match': {'featured': true}}
              ]
            }
          }
        }
      },
      {
        'name': 'Nested Query',
        'description': 'Query nested objects with specific conditions',
        'query': {
          'query': {
            'nested': {
              'path': 'comments',
              'query': {
                'bool': {
                  'must': [
                    {'match': {'comments.author': 'john'}},
                    {'range': {'comments.date': {'gte': 'now-1M'}}}
                  ]
                }
              }
            }
          }
        }
      },
      {
        'name': 'Advanced Aggregations',
        'description': 'Multiple aggregations with sub-aggregations',
        'query': {
          'size': 0,
          'aggs': {
            'categories': {
              'terms': {
                'field': 'category.keyword',
                'size': 10
              },
              'aggs': {
                'avg_score': {
                  'avg': {
                    'field': 'score'
                  }
                },
                'date_histogram': {
                  'date_histogram': {
                    'field': '@timestamp',
                    'calendar_interval': 'month'
                  }
                }
              }
            }
          }
        }
      },
    ];

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books_rounded,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Query Library',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
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
            Expanded(
              child: ListView.builder(
                itemCount: queries.length,
                itemBuilder: (context, index) {
                  final queryData = queries[index];
                  return UltraSafeWidget(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          queryData['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(queryData['description'] as String),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // This would need to be connected to the query controller
                          },
                          child: const Text('Use'),
                        ),
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
}