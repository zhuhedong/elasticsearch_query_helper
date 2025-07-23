import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/elasticsearch_config.dart';
import '../providers/elasticsearch_provider.dart';
import '../utils/auth_validator.dart';
import '../widgets/quick_connect_widget.dart';

class ConnectionCard extends StatefulWidget {
  const ConnectionCard({super.key});

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '9200');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _indexPatternController = TextEditingController();

  String _selectedScheme = 'http';
  String _selectedVersion = 'v7';
  String _selectedAuthType = 'none';
  
  AuthValidationResult? _authValidation;
  bool _showAuthPreview = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    _indexPatternController.dispose();
    super.dispose();
  }

  void _validateAuth() {
    setState(() {
      if (_selectedAuthType == 'basic') {
        _authValidation = AuthValidator.validateBasicAuth(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else if (_selectedAuthType == 'apikey') {
        _authValidation = AuthValidator.validateApiKey(
          _apiKeyController.text.trim(),
        );
      } else {
        _authValidation = null;
      }
    });
  }

  void _loadConfig(ElasticsearchConfig config) {
    setState(() {
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      _selectedScheme = config.scheme;
      _selectedVersion = config.version;
      _usernameController.text = config.username ?? '';
      _passwordController.text = config.password ?? '';
      _apiKeyController.text = config.apiKey ?? '';
      _indexPatternController.text = config.indexPattern ?? '';
      
      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
        _selectedAuthType = 'apikey';
      } else if (config.username != null && config.username!.isNotEmpty) {
        _selectedAuthType = 'basic';
      } else {
        _selectedAuthType = 'none';
      }
    });
    
    // Validate authentication after loading
    _validateAuth();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final config = ElasticsearchConfig(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      scheme: _selectedScheme,
      version: _selectedVersion,
      username: _selectedAuthType == 'basic' ? _usernameController.text.trim() : null,
      password: _selectedAuthType == 'basic' ? _passwordController.text.trim() : null,
      apiKey: _selectedAuthType == 'apikey' ? _apiKeyController.text.trim() : null,
      indexPattern: _indexPatternController.text.trim().isEmpty 
          ? null 
          : _indexPatternController.text.trim(),
    );

    final provider = Provider.of<ElasticsearchProvider>(context, listen: false);
    await provider.setConfig(config);
    await provider.testConnection();
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
                'Elasticsearch Connection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to your Elasticsearch cluster to start querying data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              
              // Connection Status
              if (provider.config != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.isConnected 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    border: Border.all(
                      color: provider.isConnected 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider.isConnected 
                            ? Icons.check_circle 
                            : Icons.warning,
                        color: provider.isConnected 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.isConnected 
                                  ? 'Connected to ${provider.config!.host}:${provider.config!.port}'
                                  : 'Configuration saved - Click "Connect" to test',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (provider.isConnected && provider.clusterHealth != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Cluster: ${provider.clusterHealth!['cluster_name'] ?? 'Unknown'} | '
                                'Status: ${provider.clusterHealth!['status'] ?? 'Unknown'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Saved Configurations
              if (provider.savedConfigs.isNotEmpty) ...[
                Text(
                  'Saved Configurations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.savedConfigs.length,
                    itemBuilder: (context, index) {
                      final config = provider.savedConfigs[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 8),
                        child: Card(
                          child: InkWell(
                            onTap: () => _loadConfig(config),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${config.host}:${config.port}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text('Version: ${config.version}'),
                                  Text('Scheme: ${config.scheme}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Connect Section
              const QuickConnectWidget(),
              const SizedBox(height: 16),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Basic Connection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Basic Settings',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller: _hostController,
                                        decoration: const InputDecoration(
                                          labelText: 'Host',
                                          hintText: 'localhost',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a host';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _portController,
                                        decoration: const InputDecoration(
                                          labelText: 'Port',
                                          hintText: '9200',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a port';
                                          }
                                          final port = int.tryParse(value);
                                          if (port == null || port < 1 || port > 65535) {
                                            return 'Invalid port';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedScheme,
                                        decoration: const InputDecoration(
                                          labelText: 'Scheme',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['http', 'https']
                                            .map((scheme) => DropdownMenuItem(
                                                  value: scheme,
                                                  child: Text(scheme.toUpperCase()),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedScheme = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedVersion,
                                        decoration: const InputDecoration(
                                          labelText: 'ES Version',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['v6', 'v7', 'v8']
                                            .map((version) => DropdownMenuItem(
                                                  value: version,
                                                  child: Text(version.toUpperCase()),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedVersion = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Authentication
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Authentication',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedAuthType,
                                  decoration: const InputDecoration(
                                    labelText: 'Authentication Type',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: 'none', child: Text('None')),
                                    const DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
                                    const DropdownMenuItem(value: 'apikey', child: Text('API Key')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAuthType = value!;
                                      _authValidation = null;
                                    });
                                    _validateAuth();
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_selectedAuthType == 'basic') ...[
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => _validateAuth(),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(),
                                    ),
                                    obscureText: true,
                                    onChanged: (_) => _validateAuth(),
                                  ),
                                ] else if (_selectedAuthType == 'apikey') ...[
                                  TextFormField(
                                    controller: _apiKeyController,
                                    decoration: const InputDecoration(
                                      labelText: 'API Key',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => _validateAuth(),
                                  ),
                                ],
                                
                                // Authentication validation display
                                if (_authValidation != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _authValidation!.isValid 
                                          ? Colors.green.shade50 
                                          : Colors.red.shade50,
                                      border: Border.all(
                                        color: _authValidation!.isValid 
                                            ? Colors.green 
                                            : Colors.red,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _authValidation!.isValid 
                                                  ? Icons.check_circle 
                                                  : Icons.error,
                                              color: _authValidation!.isValid 
                                                  ? Colors.green 
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _authValidation!.isValid 
                                                  ? 'Authentication Valid' 
                                                  : 'Authentication Error',
                                              style: TextStyle(
                                                color: _authValidation!.isValid 
                                                    ? Colors.green.shade700 
                                                    : Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_authValidation!.hasError) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _authValidation!.error!,
                                            style: TextStyle(color: Colors.red.shade700),
                                          ),
                                        ],
                                        if (_authValidation!.hasWarning) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _authValidation!.warning!,
                                            style: TextStyle(color: Colors.orange.shade700),
                                          ),
                                        ],
                                        if (_authValidation!.hasSuggestion) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Suggestion: ${_authValidation!.suggestion!}',
                                            style: TextStyle(color: Colors.blue.shade700),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Authentication preview toggle
                                if (_selectedAuthType != 'none') ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _showAuthPreview,
                                        onChanged: (value) {
                                          setState(() {
                                            _showAuthPreview = value ?? false;
                                          });
                                        },
                                      ),
                                      const Text('Show authentication header preview'),
                                    ],
                                  ),
                                  if (_showAuthPreview) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Authentication Header:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AuthValidator.getAuthHeaderPreview(
                                              username: _selectedAuthType == 'basic' 
                                                  ? _usernameController.text.trim() 
                                                  : null,
                                              password: _selectedAuthType == 'basic' 
                                                  ? _passwordController.text.trim() 
                                                  : null,
                                              apiKey: _selectedAuthType == 'apikey' 
                                                  ? _apiKeyController.text.trim() 
                                                  : null,
                                            ),
                                            style: const TextStyle(fontFamily: 'monospace'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Optional Settings
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Optional Settings',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _indexPatternController,
                                  decoration: const InputDecoration(
                                    labelText: 'Default Index Pattern',
                                    hintText: 'logs-*',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _connect,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: provider.isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      provider.isConnected ? 'Reconnect' : 'Connect',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}