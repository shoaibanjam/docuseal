#!/bin/bash

# DocuSeal Deployment Script (Non-Docker)
# This script deploys DocuSeal without using Docker

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_warn "It's not recommended to run this script as root"
fi

print_info "Starting DocuSeal deployment..."

# Check for required commands
print_info "Checking for required dependencies..."

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

check_command ruby
check_command bundle
check_command node
check_command yarn

# Check Ruby version
RUBY_VERSION=$(ruby -v | awk '{print $2}' | cut -d'p' -f1)
REQUIRED_RUBY="4.0.1"
if [ "$(printf '%s\n' "$REQUIRED_RUBY" "$RUBY_VERSION" | sort -V | head -n1)" != "$REQUIRED_RUBY" ]; then
    print_warn "Ruby version $RUBY_VERSION detected. Recommended: $REQUIRED_RUBY"
fi

print_info "All dependencies found ✓"

# Set environment
export RAILS_ENV=${RAILS_ENV:-production}
export NODE_ENV=${NODE_ENV:-production}

print_info "Environment: $RAILS_ENV"

# Install Ruby dependencies
print_info "Installing Ruby dependencies..."
bundle install --deployment --without development test

# Install Node dependencies
print_info "Installing Node dependencies..."
yarn install --frozen-lockfile --production

# Check for database configuration
if [ -z "$DATABASE_URL" ] && [ -z "$DATABASE_HOST" ]; then
    print_warn "No DATABASE_URL or DATABASE_HOST set. Will use SQLite (not recommended for production)"
    print_warn "To use PostgreSQL, set DATABASE_URL or DATABASE_HOST environment variables"
fi

# Setup database
print_info "Setting up database..."
if [ "$RAILS_ENV" = "production" ]; then
    bundle exec rails db:create db:migrate
else
    bundle exec rails db:create db:migrate db:seed
fi

# Precompile assets
print_info "Precompiling assets..."
bundle exec rails assets:precompile

# Clear old assets
print_info "Clearing old assets..."
bundle exec rails tmp:clear

# Create necessary directories
print_info "Creating necessary directories..."
mkdir -p tmp/pids
mkdir -p log
mkdir -p storage
mkdir -p public/uploads

# Set permissions
print_info "Setting permissions..."
chmod -R 755 tmp log storage public/uploads

# Check if we should start the server
if [ "$1" = "--start" ]; then
    print_info "Starting application server..."
    
    # Check if PORT is set
    if [ -z "$PORT" ]; then
        export PORT=3000
        print_warn "PORT not set, using default: $PORT"
    fi
    
    # Start using Procfile
    if command -v foreman &> /dev/null; then
        print_info "Starting with Foreman..."
        foreman start web
    else
        print_info "Starting with Puma directly..."
        bundle exec puma -p $PORT -C ./config/puma.rb
    fi
else
    print_info "Deployment completed successfully!"
    print_info "To start the server, run: ./deploy.sh --start"
    print_info "Or use: bundle exec puma -p \$PORT -C ./config/puma.rb"
    print_info ""
    print_info "Make sure to set the following environment variables:"
    print_info "  - RAILS_ENV (default: production)"
    print_info "  - PORT (default: 3000)"
    print_info "  - DATABASE_URL or DATABASE_HOST/DATABASE_NAME/DATABASE_USER/DATABASE_PASSWORD"
    print_info "  - SECRET_KEY_BASE (run: bundle exec rails secret)"
    print_info "  - Any other required environment variables for your setup"
fi
