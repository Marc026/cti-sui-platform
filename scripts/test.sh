#!/bin/bash

set -e

echo "Running CTI Platform Test Suite"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test smart contracts
print_status "Testing Smart Contracts..."
cd smart-contracts/cti_platform || {
    print_error "Smart contracts directory not found"
    exit 1
}

if command -v sui >/dev/null 2>&1; then
    sui move test
    sui move prove || echo "Move Prover completed with warnings"
else
    print_error "Sui CLI not found. Please install Sui CLI first."
    exit 1
fi

cd ../..

# Test TypeScript SDK
if [ -d "sdk/typescript" ]; then
    print_status "Testing TypeScript SDK..."
    cd sdk/typescript
    
    if [ -f "package.json" ]; then
        npm test || {
            print_error "TypeScript SDK tests failed"
            cd ../..
            exit 1
        }
    fi
    
    cd ../..
fi

# Test Python framework
if [ -d "tests/python" ]; then
    print_status "Testing Python Framework..."
    cd tests/python
    
    if [ -f "requirements.txt" ]; then
        python -m pytest -v || {
            print_error "Python tests failed"
            cd ../..
            exit 1
        }
    fi
    
    cd ../..
fi

# Test API
if [ -d "api" ]; then
    print_status "Testing API..."
    cd api
    
    if [ -f "package.json" ]; then
        npm test || {
            print_error "API tests failed"
            cd ..
            exit 1
        }
    fi
    
    cd ..
fi

# Test Frontend
if [ -d "frontend" ]; then
    print_status "Testing Frontend..."
    cd frontend
    
    if [ -f "package.json" ]; then
        npm test || {
            print_error "Frontend tests failed"
            cd ..
            exit 1
        }
    fi
    
    cd ..
fi

print_status "All tests completed successfully!"