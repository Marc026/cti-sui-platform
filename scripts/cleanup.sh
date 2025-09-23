# scripts/cleanup.sh
#!/bin/bash
# Cleanup script for development environment

set -e

echo "Cleaning up CTI Platform development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop Docker containers
if command -v docker-compose >/dev/null 2>&1; then
    print_status "Stopping Docker containers..."
    docker-compose down -v 2>/dev/null || true
fi

# Kill any running processes
print_status "Stopping running processes..."
pkill -f "sui start" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true
pkill -f "node src/server.js" 2>/dev/null || true

# Clean build artifacts
print_status "Cleaning build artifacts..."
rm -rf smart-contracts/build 2>/dev/null || true
rm -rf api/node_modules/.cache 2>/dev/null || true
rm -rf frontend/.next 2>/dev/null || true
rm -rf sdk/typescript/dist 2>/dev/null || true

# Clean logs
print_status "Cleaning logs..."
rm -rf logs/*.log 2>/dev/null || true
rm -rf api/logs/*.log 2>/dev/null || true

# Remove PID files
print_status "Removing PID files..."
rm -f *.pid 2>/dev/null || true

# Clean test artifacts
print_status "Cleaning test artifacts..."
rm -rf coverage 2>/dev/null || true
rm -rf .pytest_cache 2>/dev/null || true
rm -rf tests/python/__pycache__ 2>/dev/null || true

print_status "Cleanup completed successfully!"
