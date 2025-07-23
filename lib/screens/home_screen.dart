import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../widgets/connection_card.dart';
import '../widgets/query_panel.dart';
import '../widgets/results_panel.dart';
import '../widgets/cluster_info_panel.dart';
import '../widgets/quick_actions_bar.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Elasticsearch Query Helper'),
          ],
        ),
        actions: [
          Consumer<ElasticsearchProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusIndicator(
                  isActive: provider.isConnected,
                  label: provider.isConnected
                      ? 'Connected'
                      : provider.config != null
                          ? 'Disconnected'
                          : 'No Connection',
                  icon: provider.isConnected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions Bar
          const QuickActionsBar(),
          
          // Main content
          Expanded(
            child: Row(
              children: [
                // Modern navigation rail
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.settings_rounded),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Connection'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: Text('Query'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_chart_rounded),
                  selectedIcon: Icon(Icons.table_chart_rounded),
                  label: Text('Results'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.info_rounded),
                  selectedIcon: Icon(Icons.info_rounded),
                  label: Text('Cluster'),
                ),
              ],
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: Consumer<ElasticsearchProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading...'),
                              ],
                            ),
                          );
                        }

                        if (provider.error != null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: ModernCard(
                                backgroundColor: AppTheme.accentRed.withOpacity(0.05),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: AppTheme.accentRed,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Connection Error',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.accentRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      provider.error!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => provider.testConnection(),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry Connection'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return _buildContent(context, provider);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ElasticsearchProvider provider) {
    switch (_selectedIndex) {
      case 0:
        return const ConnectionCard();
      case 1:
        return const QueryPanel();
      case 2:
        return const ResultsPanel();
      case 3:
        return const ClusterInfoPanel();
      default:
        return const ConnectionCard();
    }
  }
}