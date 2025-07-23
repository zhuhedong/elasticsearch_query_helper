#!/bin/bash

# Elasticsearch Query Helper - Installation Script
# This script installs the application and creates desktop integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
INSTALL_DIR="$HOME/.local/share/elasticsearch-query-helper"
DESKTOP_FILE="$HOME/.local/share/applications/elasticsearch-query-helper.desktop"
BIN_DIR="$HOME/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install the application
install_app() {
    print_status "Installing Elasticsearch Query Helper..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    
    # Copy application files
    print_status "Copying application files..."
    cp -r "$PROJECT_DIR"/* "$INSTALL_DIR/"
    
    # Make run script executable
    chmod +x "$INSTALL_DIR/run.sh"
    
    # Create symlink in bin directory
    ln -sf "$INSTALL_DIR/run.sh" "$BIN_DIR/elasticsearch-query-helper"
    
    # Create desktop file
    print_status "Creating desktop integration..."
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Elasticsearch Query Helper
Comment=A powerful tool for managing Elasticsearch queries with multi-version support
Exec=$INSTALL_DIR/run.sh
Icon=$INSTALL_DIR/assets/icon.png
Terminal=false
Categories=Development;Database;Utility;
Keywords=elasticsearch;search;database;query;json;
StartupNotify=true
StartupWMClass=elasticsearch_query_helper
EOF
    
    # Make desktop file executable
    chmod +x "$DESKTOP_FILE"
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    print_success "Installation completed successfully!"
    print_status "Application installed to: $INSTALL_DIR"
    print_status "Desktop file created: $DESKTOP_FILE"
    print_status "Command line launcher: $BIN_DIR/elasticsearch-query-helper"
}

# Function to uninstall the application
uninstall_app() {
    print_status "Uninstalling Elasticsearch Query Helper..."
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed application directory"
    fi
    
    # Remove desktop file
    if [ -f "$DESKTOP_FILE" ]; then
        rm -f "$DESKTOP_FILE"
        print_success "Removed desktop file"
    fi
    
    # Remove symlink
    if [ -L "$BIN_DIR/elasticsearch-query-helper" ]; then
        rm -f "$BIN_DIR/elasticsearch-query-helper"
        print_success "Removed command line launcher"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    print_success "Uninstallation completed!"
}

# Function to check if application is installed
check_installation() {
    if [ -d "$INSTALL_DIR" ] && [ -f "$DESKTOP_FILE" ]; then
        print_success "Elasticsearch Query Helper is installed"
        print_status "Installation directory: $INSTALL_DIR"
        print_status "Desktop file: $DESKTOP_FILE"
        if [ -L "$BIN_DIR/elasticsearch-query-helper" ]; then
            print_status "Command line launcher: $BIN_DIR/elasticsearch-query-helper"
        fi
        return 0
    else
        print_warning "Elasticsearch Query Helper is not installed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Elasticsearch Query Helper - Installation Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     Install the application (default)"
    echo "  uninstall   Remove the application"
    echo "  status      Check installation status"
    echo "  help        Show this help message"
    echo ""
    echo "Installation locations:"
    echo "  Application: $INSTALL_DIR"
    echo "  Desktop file: $DESKTOP_FILE"
    echo "  Command launcher: $BIN_DIR/elasticsearch-query-helper"
    echo ""
    echo "After installation, you can:"
    echo "  - Launch from application menu"
    echo "  - Run from command line: elasticsearch-query-helper"
    echo "  - Run directly: $INSTALL_DIR/run.sh"
}

# Main script logic
main() {
    case "${1:-install}" in
        "install")
            install_app
            ;;
        "uninstall")
            uninstall_app
            ;;
        "status")
            check_installation
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"