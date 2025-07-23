# Elasticsearch Query Helper - User Guide

## Overview
The Elasticsearch Query Helper is a Flutter-based desktop application that provides an intuitive interface for creating, testing, and managing Elasticsearch queries. This guide covers the latest improvements and how to use the application effectively.

## Recent Improvements

### 🔧 Technical Fixes
- **Authentication System**: Fixed base64 encoding bug that prevented proper authentication
- **Crash Prevention**: Resolved null check operator crashes with defensive programming
- **GTK Compatibility**: Improved Linux desktop integration (some warnings expected in headless environments)
- **Layout Issues**: Fixed UI overflow problems with scrollable containers

### 🎨 User Experience Enhancements
- **Welcome Screen**: New user-friendly onboarding experience
- **Connection Status**: Real-time indicators showing Elasticsearch connection status
- **Query Templates**: Pre-built query examples for common use cases
- **Visual Query Builder**: Drag-and-drop interface for building queries (coming soon)
- **Error Handling**: Comprehensive error messages and debugging information

## Getting Started

### 1. Installation
```bash
# Clone the repository
git clone <repository-url>
cd elasticsearch_query_helper

# Make the run script executable
chmod +x run.sh

# Build the application
./run.sh build
```

### 2. Configuration
The application supports multiple authentication methods:

- **Basic Authentication**: Username and password
- **API Key**: Elasticsearch API key
- **Bearer Token**: OAuth/JWT tokens

Configuration is automatically saved and validated in real-time.

### 3. Running the Application
```bash
# Run the application
./run.sh run

# Or run directly
./build/linux/x64/release/bundle/elasticsearch_query_helper
```

## Features

### Connection Management
- **Real-time Validation**: Credentials are validated as you type
- **Connection Testing**: Test connections before saving
- **Status Indicators**: Visual feedback on connection health
- **Multiple Environments**: Save configurations for different Elasticsearch clusters

### Query Interface
- **Syntax Highlighting**: JSON syntax highlighting for queries
- **Auto-completion**: Smart suggestions for Elasticsearch query DSL
- **Query Templates**: Pre-built templates for common operations:
  - Match All queries
  - Term queries
  - Range queries
  - Bool queries
  - Aggregations

### Results Display
- **Formatted Output**: Pretty-printed JSON responses
- **Pagination**: Navigate through large result sets
- **Export Options**: Save results to files
- **Error Details**: Comprehensive error information for debugging

### Visual Query Builder (Coming Soon)
- **Drag-and-Drop**: Build queries visually without writing JSON
- **Field Browser**: Explore index mappings and field types
- **Query Preview**: See generated JSON in real-time
- **Template Library**: Save and reuse custom query patterns

## Usage Tips

### 1. Authentication
- Use the preview feature to verify your credentials before connecting
- API keys are recommended for production environments
- Basic auth is suitable for development and testing

### 2. Query Building
- Start with templates and modify them for your needs
- Use the JSON editor for complex queries
- Test queries incrementally to identify issues early

### 3. Performance
- Use filters instead of queries when possible for better performance
- Limit result sizes with `size` parameter
- Use `_source` filtering to reduce response payload

### 4. Troubleshooting
- Check the connection status indicator
- Review error messages in the results panel
- Use the debug mode for detailed logging
- Verify Elasticsearch cluster health

## Keyboard Shortcuts

- **Ctrl+Enter**: Execute query
- **Ctrl+S**: Save current query
- **Ctrl+N**: New query
- **Ctrl+O**: Open saved query
- **F5**: Refresh connection status

## Configuration Files

The application stores configuration in:
- **Linux**: `~/.config/elasticsearch_query_helper/`
- **Settings**: Connection details, saved queries, preferences

## System Requirements

- **Operating System**: Linux (Ubuntu 20.04+, other distributions)
- **Dependencies**: GTK+3, libgtk-3-dev
- **Flutter**: 3.24.5 or later
- **Memory**: 512MB RAM minimum
- **Storage**: 100MB available space

## Troubleshooting

### Common Issues

1. **GTK Warnings**: Normal in headless environments, doesn't affect functionality
2. **Connection Failures**: Check Elasticsearch URL and credentials
3. **Layout Issues**: Resize window or restart application
4. **Performance**: Close unused query tabs, limit result sizes

### Debug Mode
Run with debug flags for detailed logging:
```bash
export FLUTTER_DEBUG=1
./run.sh run
```

### Log Files
Application logs are available in:
- Console output during execution
- System logs via `journalctl`

## Development

### Building from Source
```bash
# Install Flutter SDK
# Install dependencies
sudo apt-get install libgtk-3-dev

# Build
flutter build linux --release
```

### Testing
```bash
# Run test suite
./test_app.sh

# Unit tests
flutter test

# Integration tests
flutter integration_test
```

## Support

For issues and feature requests:
1. Check the troubleshooting section
2. Review application logs
3. Test with minimal query examples
4. Document error messages and steps to reproduce

## Changelog

### Latest Version
- ✅ Fixed authentication encoding bug
- ✅ Added welcome screen and onboarding
- ✅ Improved error handling and debugging
- ✅ Fixed UI layout overflow issues
- ✅ Enhanced connection status indicators
- ✅ Added query templates and examples
- 🔄 Visual query builder (in development)
- 🔄 Advanced result filtering (planned)
- 🔄 Query performance analytics (planned)

---

**Note**: This application is designed for desktop environments with X11. Some warnings in headless environments are expected and don't affect functionality.