#!/bin/bash

# Elasticsearch Query Helper - Launch Script
# This script provides a convenient way to run the Elasticsearch Query Helper

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

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

# Check if Flutter is available
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        if [ -f "/opt/flutter/bin/flutter" ]; then
            export PATH="/opt/flutter/bin:$PATH"
            print_warning "Flutter found in /opt/flutter, added to PATH"
        else
            print_error "Flutter is not installed or not in PATH"
            print_error "Please install Flutter or add it to your PATH"
            exit 1
        fi
    fi
    
    print_status "Flutter version: $(flutter --version | head -1)"
}

# Check system dependencies
check_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check GTK+3
    if ! pkg-config --exists gtk+-3.0; then
        print_error "GTK+3 development libraries not found"
        print_error "Please install: sudo pacman -S gtk3 (Arch/Manjaro) or sudo apt-get install libgtk-3-dev (Ubuntu/Debian)"
        exit 1
    fi
    
    print_success "All dependencies are satisfied"
}

# Function to build the application
build_app() {
    print_status "Building Elasticsearch Query Helper..."
    
    cd "$PROJECT_DIR"
    
    # Clean previous build
    flutter clean > /dev/null 2>&1
    
    # Get dependencies
    flutter pub get
    
    # Build for Linux
    flutter build linux --release
    
    if [ $? -eq 0 ]; then
        print_success "Build completed successfully"
        print_status "Executable location: build/linux/x64/release/bundle/elasticsearch_query_helper"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Function to run the application
run_app() {
    print_status "Starting Elasticsearch Query Helper..."
    
    cd "$PROJECT_DIR"
    
    # Check if built version exists
    if [ ! -f "build/linux/x64/release/bundle/elasticsearch_query_helper" ]; then
        print_warning "Release build not found, building now..."
        build_app
    fi
    
    # Run the application
    print_status "Launching application..."
    cd build/linux/x64/release/bundle
    ./elasticsearch_query_helper
}

# Function to run in development mode
run_dev() {
    print_status "Starting Elasticsearch Query Helper in development mode..."
    
    cd "$PROJECT_DIR"
    flutter run -d linux
}

# Function to show usage
show_usage() {
    echo "Elasticsearch Query Helper - Launch Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  run       Run the application (default)"
    echo "  dev       Run in development mode with hot reload"
    echo "  build     Build the application for release"
    echo "  check     Check system dependencies"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Run the application"
    echo "  $0 dev          # Run in development mode"
    echo "  $0 build        # Build for release"
}

# Main script logic
main() {
    case "${1:-run}" in
        "run")
            check_flutter
            check_dependencies
            run_app
            ;;
        "dev")
            check_flutter
            check_dependencies
            run_dev
            ;;
        "build")
            check_flutter
            check_dependencies
            build_app
            ;;
        "check")
            check_flutter
            check_dependencies
            print_success "System check completed"
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