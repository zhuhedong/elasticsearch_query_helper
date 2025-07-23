import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/elasticsearch_config.dart';
import '../providers/elasticsearch_provider.dart';
import '../theme/app_theme.dart';

class QuickConnectWidget extends StatefulWidget {
  const QuickConnectWidget({super.key});

  @override
  State<QuickConnectWidget> createState() => _QuickConnectWidgetState();
}

class _QuickConnectWidgetState extends State<QuickConnectWidget> {
  final _quickUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isConnecting = false;
  bool _showAuth = false;
  String _authType = 'none'; // none, basic, apikey

  @override
  void dispose() {
    _quickUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _quickConnect() async {
    final url = _quickUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final uri = Uri.parse(url.contains('://') ? url : 'http://$url');
      final config = ElasticsearchConfig(
        host: uri.host,
        port: uri.port != 0 ? uri.port : 9200,
        scheme: uri.scheme.isEmpty ? 'http' : uri.scheme,
        version: 'v7', // Default to v7
        username: _authType == 'basic' ? _usernameController.text.trim() : null,
        password: _authType == 'basic' ? _passwordController.text.trim() : null,
        apiKey: _authType == 'apikey' ? _apiKeyController.text.trim() : null,
      );

      final provider = Provider.of<ElasticsearchProvider>(context, listen: false);
      await provider.setConfig(config);
      await provider.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Connected to ${config.host}:${config.port}'),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Connection failed: $e')),
              ],
            ),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Connect',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Elasticsearch URL to connect instantly',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickUrlController,
                  decoration: InputDecoration(
                    hintText: 'localhost:9200 or https://my-cluster.com:9200',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                  onSubmitted: (_) => _quickConnect(),
                ),
              ),
                    const SizedBox(width: 12),
                    // Auth toggle button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showAuth = !_showAuth;
                        });
                      },
                      icon: Icon(
                        _showAuth ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: _showAuth ? AppTheme.accentGreen : AppTheme.textSecondary,
                      ),
                      tooltip: _showAuth ? 'Hide authentication' : 'Show authentication',
                    ),
                    ElevatedButton(
                onPressed: _isConnecting ? null : _quickConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Connect'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Authentication section (expandable)
          if (_showAuth) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: AppTheme.accentTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Auth type selection
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildAuthTypeChip('none', 'None'),
                      _buildAuthTypeChip('basic', 'Username/Password'),
                      _buildAuthTypeChip('apikey', 'API Key'),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Auth fields
                  if (_authType == 'basic') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'elastic',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              prefixIcon: const Icon(Icons.person_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_authType == 'apikey') ...[
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'base64_encoded_api_key',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        prefixIcon: const Icon(Icons.key_rounded, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Quick presets
          Wrap(
            spacing: 8,
            children: [
              _buildPresetChip('localhost:9200', 'Local'),
              _buildPresetChip('elasticsearch:9200', 'Docker'),
              _buildPresetChip('https://elastic.cloud.es.io:9243', 'Cloud'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTypeChip(String type, String label) {
    final isSelected = _authType == type;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _authType = type;
          if (type == 'none') {
            _usernameController.clear();
            _passwordController.clear();
            _apiKeyController.clear();
          }
        });
      },
      selectedColor: AppTheme.accentTeal.withOpacity(0.2),
      checkmarkColor: AppTheme.accentTeal,
    );
  }

  Widget _buildPresetChip(String url, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _quickUrlController.text = url;
      },
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
    );
  }
}