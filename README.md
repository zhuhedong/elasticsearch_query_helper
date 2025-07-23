# Elasticsearch Query Helper

A beautiful and modern Flutter application for managing Elasticsearch connections and executing queries with ease.

## Features

### 🎨 Beautiful UI Design
- Modern Material Design 3 interface
- Smooth animations and transitions
- Dark and light theme support
- Responsive layout for desktop environments

### 🔗 Multi-Version Support
- Elasticsearch v6.x compatibility
- Elasticsearch v7.x compatibility  
- Elasticsearch v8.x compatibility
- Automatic version detection and adaptation

### 🔐 Secure Authentication
- Basic authentication (username/password)
- API key authentication
- Secure credential storage
- Connection validation

### ⚡ Quick Operations
- Fast connection management
- Pre-built query templates
- Query shortcuts and favorites
- Real-time search results

### 📊 Rich Results Display
- Beautiful result visualization
- JSON syntax highlighting
- Export capabilities
- Pagination support

## Getting Started

### Prerequisites
- Flutter SDK (>=3.13.0)
- Dart SDK (>=3.1.0)
- Linux desktop environment (primary target)

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d linux` to start the application

### First Time Setup
1. Launch the application
2. Click "New Connection" on the welcome screen
3. Enter your Elasticsearch cluster details:
   - Host (e.g., localhost)
   - Port (e.g., 9200)
   - Protocol (HTTP/HTTPS)
   - Version (v6/v7/v8)
   - Authentication (if required)
4. Test the connection
5. Start querying your data!

## UI Improvements

### Welcome Screen
- Animated logo and content
- Feature highlights
- Quick connection cards for recent connections
- Intuitive navigation buttons

### Connection Management
- Visual connection cards
- Connection status indicators
- Quick actions menu
- Bulk operations support

### Search Interface
- Syntax-highlighted query editor
- Real-time validation
- Result pagination
- Export options

## Architecture

### Safe Transform System
- UltraSafeWidget for render protection
- Global error filtering for TransformLayer issues
- Multi-layer protection system
- Graceful error handling

### Connection Management
- 15-second timeout protection
- Cancellable operations
- Comprehensive error reporting
- Automatic retry mechanisms

### State Management
- Provider pattern implementation
- Reactive UI updates
- Persistent storage
- Memory optimization

## Development

### Project Structure
```
lib/
├── main.dart              # Application entry point
├── models/               # Data models
├── providers/            # State management
├── screens/              # UI screens
├── services/             # Business logic
├── theme/                # Design system
├── utils/                # Utilities
└── widgets/              # Reusable components
```

### Key Components
- **WelcomeScreen**: Modern landing page with animations
- **ConnectionManagerScreen**: Connection CRUD operations
- **SearchScreen**: Query execution interface
- **ElasticsearchProvider**: State management
- **ElasticsearchService**: API communication

## Troubleshooting

### Common Issues
1. **Connection Timeout**: Check Elasticsearch is running and accessible
2. **Authentication Errors**: Verify credentials and security settings
3. **UI Rendering Issues**: Restart application, check system compatibility

### Debug Mode
The application includes comprehensive logging and error reporting for development and troubleshooting.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.