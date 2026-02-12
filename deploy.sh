#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_DIR=$(pwd)

# Use environment variables (can be set via .env file or export command)
# Rails will automatically load .env file when it runs, so we just use what's available
RAILS_ENV=${RAILS_ENV:-production}
PORT=${PORT:-9090}
DATABASE_URL=${DATABASE_URL:-""}
WORKDIR=${WORKDIR:-"$APP_DIR"}
HOST=${HOST:-"localhost"}

git checkout master
git pull origin master

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DocuSeal Manual Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "RAILS_ENV: ${RAILS_ENV}"
echo -e "PORT: ${PORT}"
echo -e "HOST: ${HOST}"
echo -e "WORKDIR: ${WORKDIR}"
if [ -n "$DATABASE_URL" ]; then
    echo -e "DATABASE_URL: ${DATABASE_URL:0:30}..."
else
    echo -e "DATABASE_URL: (not set, will use SQLite)"
fi
echo -e "${GREEN}========================================${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system dependencies
check_dependencies() {
    echo -e "\n${YELLOW}Checking system dependencies...${NC}"
    
    local missing_deps=()
    
    # Check PostgreSQL client
    if ! command_exists psql; then
        missing_deps+=("postgresql-client")
    fi
    
    # Check required system packages
    if command_exists apt-get; then
        # Debian/Ubuntu
        echo "Detected Debian/Ubuntu system"
        if ! dpkg -l | grep -q libpq-dev; then
            missing_deps+=("libpq-dev")
        fi
        if ! dpkg -l | grep -q build-essential; then
            missing_deps+=("build-essential")
        fi
        if ! dpkg -l | grep -q libvips-dev; then
            missing_deps+=("libvips-dev")
        fi
        if ! dpkg -l | grep -q libsqlite3-dev; then
            missing_deps+=("libsqlite3-dev")
        fi
        if ! dpkg -l | grep -q libyaml-dev; then
            missing_deps+=("libyaml-dev")
        fi
    elif command_exists yum; then
        # RHEL/CentOS
        echo "Detected RHEL/CentOS system"
        if ! rpm -q postgresql-devel >/dev/null 2>&1; then
            missing_deps+=("postgresql-devel")
        fi
        if ! rpm -q gcc gcc-c++ make >/dev/null 2>&1; then
            missing_deps+=("gcc gcc-c++ make")
        fi
        if ! rpm -q vips-devel >/dev/null 2>&1; then
            missing_deps+=("vips-devel")
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing_deps[*]}${NC}"
        echo "Please install them manually:"
        if command_exists apt-get; then
            echo "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
        elif command_exists yum; then
            echo "  sudo yum install -y ${missing_deps[*]}"
        fi
        exit 1
    fi
    
    echo -e "${GREEN}✓ All system dependencies are installed${NC}"
}

# Check Ruby version
check_ruby() {
    echo -e "\n${YELLOW}Checking Ruby installation...${NC}"
    
    if ! command_exists ruby; then
        echo -e "${RED}Ruby is not installed!${NC}"
        echo "Please install Ruby 4.0.1 using rbenv, rvm, or system package manager"
        exit 1
    fi
    
    RUBY_VERSION=$(ruby -v | cut -d' ' -f2 | cut -d'p' -f1)
    REQUIRED_VERSION="4.0.1"
    
    if [ "$RUBY_VERSION" != "$REQUIRED_VERSION" ]; then
        echo -e "${YELLOW}Warning: Ruby version is $RUBY_VERSION, recommended is $REQUIRED_VERSION${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ Ruby $RUBY_VERSION is installed${NC}"
}

# Check Node.js
check_node() {
    echo -e "\n${YELLOW}Checking Node.js installation...${NC}"
    
    if ! command_exists node; then
        echo -e "${RED}Node.js is not installed!${NC}"
        echo "Please install Node.js (version 18 or higher recommended)"
        exit 1
    fi
    
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✓ Node.js $NODE_VERSION is installed${NC}"
    
    # Check Yarn
    if ! command_exists yarn; then
        echo -e "${YELLOW}Yarn is not installed, installing...${NC}"
        npm install -g yarn
    fi
    
    echo -e "${GREEN}✓ Yarn is installed${NC}"
}

# Install Ruby gems
install_gems() {
    echo -e "\n${YELLOW}Installing Ruby gems...${NC}"
    
    if ! command_exists bundle; then
        echo "Installing Bundler..."
        gem install bundler
    fi
    
    bundle install --without development test --jobs $(nproc)
    echo -e "${GREEN}✓ Ruby gems installed${NC}"
}

# Install Node.js packages
install_node_packages() {
    echo -e "\n${YELLOW}Installing Node.js packages...${NC}"
    
    yarn install --frozen-lockfile --network-timeout 1000000
    echo -e "${GREEN}✓ Node.js packages installed${NC}"
}

# Setup database
setup_database() {
    echo -e "\n${YELLOW}Setting up database...${NC}"
    
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${YELLOW}DATABASE_URL not set in .env file. Using default SQLite database.${NC}"
        echo "To use PostgreSQL, add DATABASE_URL to your .env file:"
        echo "  DATABASE_URL=postgresql://user:password@localhost:5432/docuseal"
    else
        echo "Using DATABASE_URL from .env file"
        # Mask password in output
        DB_DISPLAY=$(echo "$DATABASE_URL" | sed 's/:[^:@]*@/:***@/')
        echo "  $DB_DISPLAY"
    fi
    
    # Export DATABASE_URL for Rails commands
    export DATABASE_URL
    
    # Run database migrations
    bundle exec rails db:create db:migrate RAILS_ENV=$RAILS_ENV || true
    echo -e "${GREEN}✓ Database setup complete${NC}"
}

# Compile assets
compile_assets() {
    echo -e "\n${YELLOW}Compiling assets...${NC}"
    
    # Compile webpack assets
    bundle exec rails shakapacker:compile RAILS_ENV=$RAILS_ENV
    
    # Precompile other assets
    bundle exec rails assets:precompile RAILS_ENV=$RAILS_ENV
    
    echo -e "${GREEN}✓ Assets compiled${NC}"
}

# Create necessary directories
create_directories() {
    echo -e "\n${YELLOW}Creating necessary directories...${NC}"
    
    mkdir -p tmp/pids
    mkdir -p tmp/cache
    mkdir -p log
    mkdir -p public/packs
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Start the server
start_server() {
    echo -e "\n${YELLOW}Starting application server...${NC}"
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "To start the server, run:"
    echo "  bundle exec puma -p $PORT -C ./config/puma.rb -e $RAILS_ENV"
    echo ""
    echo "Or use systemd/service manager to run it as a service."
    echo ""
    echo "Application will be available at: http://localhost:$PORT"
    echo ""
}

# Main deployment flow
main() {
    check_dependencies
    check_ruby
    check_node
    create_directories
    install_gems
    install_node_packages
    setup_database
    compile_assets
    start_server
}

# Run main function
main
