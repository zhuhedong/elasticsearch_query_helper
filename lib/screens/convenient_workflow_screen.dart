import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../widgets/quick_connect_widget.dart';
import '../widgets/index_selector.dart';
import '../widgets/quick_search_panel.dart';
import '../widgets/results_panel.dart';
import '../theme/app_theme.dart';

class ConvenientWorkflowScreen extends StatefulWidget {
  const ConvenientWorkflowScreen({super.key});

  @override
  State<ConvenientWorkflowScreen> createState() => _ConvenientWorkflowScreenState();
}

class _ConvenientWorkflowScreenState extends State<ConvenientWorkflowScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-load indices when connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ElasticsearchProvider>(context, listen: false);
      if (provider.isConnected) {
        provider.loadIndices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Elasticsearch Query Helper',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ElasticsearchProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    // Connection status
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ElasticsearchProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Step indicator
                _buildStepIndicator(provider),
                const SizedBox(height: 16),
                
                // Main workflow
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel - Connection and Index Selection
                      SizedBox(
                        width: 350,
                        child: Column(
                          children: [
                            // Step 1: Connection
                            if (!provider.isConnected) ...[
                              Expanded(
                                child: _buildConnectionStep(),
                              ),
                            ] else ...[
                              // Step 2: Index Selection
                              Expanded(
                                child: IndexSelector(
                                  onIndexSelected: (index) {
                                    // Auto-load indices when index is selected
                                    if (provider.indices.isEmpty) {
                                      provider.loadIndices();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Middle panel - Search
                      SizedBox(
                        width: 400,
                        child: provider.isConnected 
                            ? const QuickSearchPanel()
                            : _buildPlaceholderPanel(
                                'Quick Search',
                                'Connect to Elasticsearch to start searching',
                                Icons.search_rounded,
                              ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Right panel - Results
                      Expanded(
                        child: provider.isConnected 
                            ? const ResultsPanel()
                            : _buildPlaceholderPanel(
                                'Search Results',
                                'Results will appear here after searching',
                                Icons.table_chart_rounded,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(ElasticsearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildStepItem(
            1,
            'Connect',
            provider.isConnected,
            Icons.link_rounded,
          ),
          _buildStepArrow(),
          _buildStepItem(
            2,
            'Select Index',
            provider.isConnected && provider.selectedIndex != null,
            Icons.list_rounded,
          ),
          _buildStepArrow(),
          _buildStepItem(
            3,
            'Search',
            provider.isConnected && provider.selectedIndex != null,
            Icons.search_rounded,
          ),
          _buildStepArrow(),
          _buildStepItem(
            4,
            'Results',
            provider.lastSearchResult != null,
            Icons.table_chart_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $step',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive 
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildConnectionStep() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  Icons.link_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Step 1: Connect to Elasticsearch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: QuickConnectWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPanel(String title, String description, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}