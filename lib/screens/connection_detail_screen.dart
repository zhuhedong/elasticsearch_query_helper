import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/elasticsearch_provider.dart';
import '../models/elasticsearch_config.dart';
import '../theme/app_theme.dart';

class ConnectionDetailScreen extends StatefulWidget {
  final ElasticsearchConfig? config;
  
  const ConnectionDetailScreen({super.key, this.config});

  @override
  State<ConnectionDetailScreen> createState() => _ConnectionDetailScreenState();
}

class _ConnectionDetailScreenState extends State<ConnectionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  
  String _selectedVersion = 'v7';
  String _authType = 'none';
  bool _isPasswordVisible = false;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _loadExistingConfig();
    } else {
      _setDefaults();
    }
  }

  void _loadExistingConfig() {
    final config = widget.config!;
    _nameController.text = config.name;
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _selectedVersion = config.version;
    
    if (config.username != null && config.username!.isNotEmpty) {
      _authType = 'basic';
      _usernameController.text = config.username!;
      _passwordController.text = config.password ?? '';
    } else if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      _authType = 'apikey';
      _apiKeyController.text = config.apiKey!;
    } else {
      _authType = 'none';
    }
  }

  void _setDefaults() {
    _hostController.text = 'localhost';
    _portController.text = '9200';
    _selectedVersion = 'v7';
    _authType = 'none';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.config != null;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Connection' : 'Add Connection',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _saveConnection,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildConnectionSection(),
            const SizedBox(height: 24),
            _buildAuthenticationSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 添加这个限制
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Connection Name (Optional)',
                hintText: 'e.g., Production ES, Local Development',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 添加这个限制
          children: [
            Row(
              children: [
                Icon(Icons.storage_outlined, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Connection Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'Host *',
                hintText: 'localhost or IP address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Host is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port *',
                hintText: '9200',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.settings_input_antenna),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Port is required';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Please enter a valid port number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVersion,
              decoration: InputDecoration(
                labelText: 'Elasticsearch Version',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.settings),
              ),
              items: const [
                DropdownMenuItem(value: 'v6', child: Text('6.x')),
                DropdownMenuItem(value: 'v7', child: Text('7.x')),
                DropdownMenuItem(value: 'v8', child: Text('8.x')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVersion = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 添加这个限制
          children: [
            Row(
              children: [
                Icon(Icons.security_outlined, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Authentication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              decoration: InputDecoration(
                labelText: 'Authentication Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No Authentication')),
                DropdownMenuItem(value: 'basic', child: Text('Username & Password')),
                DropdownMenuItem(value: 'apikey', child: Text('API Key')),
              ],
              onChanged: (value) {
                setState(() {
                  _authType = value!;
                });
              },
            ),
            if (_authType == 'basic') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: _authType == 'basic' ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required for basic authentication';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: _authType == 'basic' ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required for basic authentication';
                  }
                  return null;
                } : null,
              ),
            ],
            if (_authType == 'apikey') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your Elasticsearch API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isApiKeyVisible = !_isApiKeyVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isApiKeyVisible,
                validator: _authType == 'apikey' ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Key is required for API key authentication';
                  }
                  return null;
                } : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min, // 添加这个限制
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_tethering),
                SizedBox(width: 8),
                Text(
                  'Test Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save),
                const SizedBox(width: 8),
                Text(
                  widget.config != null ? 'Update Connection' : 'Save Connection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = _createConfig();
    
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
      final provider = context.read<ElasticsearchProvider>();
      await provider.setConfig(config);
      final success = await provider.testConnection();
      
      if (mounted) {
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
      if (mounted) {
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

  void _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = _createConfig();
    
    try {
      final provider = context.read<ElasticsearchProvider>();
      await provider.saveConnection(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.config != null 
                  ? 'Connection updated successfully'
                  : 'Connection saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ElasticsearchConfig _createConfig() {
    return ElasticsearchConfig(
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      version: _selectedVersion,
      username: _authType == 'basic' ? _usernameController.text.trim() : null,
      password: _authType == 'basic' ? _passwordController.text : null,
      apiKey: _authType == 'apikey' ? _apiKeyController.text.trim() : null,
    );
  }
}