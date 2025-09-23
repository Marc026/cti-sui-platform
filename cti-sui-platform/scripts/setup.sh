set -e

echo "CTI Platform Initial Setup"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Consider using a non-root user."
fi

# Create necessary directories
print_status "Creating directories..."
mkdir -p logs
mkdir -p data
mkdir -p backups
mkdir -p docs
mkdir -p api/logs

# Setup environment file
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cp .env.template .env
    print_warning "Please edit .env file with your configuration"
else
    print_status ".env file already exists"
fi

# Install dependencies
print_status "Installing dependencies..."

# Check for Node.js
if command -v node >/dev/null 2>&1; then
    print_status "Node.js found: $(node --version)"
    
    # Install API dependencies
    if [ -d "api" ]; then
        print_status "Installing API dependencies..."
        cd api
        npm install
        cd ..
    fi
    
    # Install Frontend dependencies
    if [ -d "frontend" ]; then
        print_status "Installing Frontend dependencies..."
        cd frontend
        npm install
        cd ..
    fi
    
    # Install SDK dependencies
    if [ -d "sdk/typescript" ]; then
        print_status "Installing SDK dependencies..."
        cd sdk/typescript
        npm install
        cd ../..
    fi
else
    print_warning "Node.js not found. Please install Node.js 18+"
fi

# Check for Python
if command -v python3 >/dev/null 2>&1; then
    print_status "Python found: $(python3 --version)"
    
    # Install Python dependencies
    if [ -d "tests/python" ]; then
        print_status "Installing Python dependencies..."
        cd tests/python
        pip3 install -r requirements.txt
        cd ../..
    fi
else
    print_warning "Python 3 not found. Please install Python 3.11+"
fi

# Check for Rust and Sui
if command -v cargo >/dev/null 2>&1; then
    print_status "Rust found: $(rustc --version)"
    
    # Install Sui CLI if not present
    if ! command -v sui >/dev/null 2>&1; then
        print_status "Installing Sui CLI..."
        cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
    else
        print_status "Sui CLI found: $(sui --version)"
    fi
else
    print_warning "Rust not found. Please install Rust to build smart contracts"
fi

# Check for Docker
if command -v docker >/dev/null 2>&1; then
    print_status "Docker found: $(docker --version)"
    
    if command -v docker-compose >/dev/null 2>&1; then
        print_status "Docker Compose found"
    else
        print_warning "Docker Compose not found. Install for containerized deployment"
    fi
else
    print_warning "Docker not found. Install for containerized deployment"
fi

# Set executable permissions on scripts
print_status "Setting script permissions..."
chmod +x scripts/*.sh

print_status "Setup completed!"
print_status "Next steps:"
print_status "1. Edit .env file with your configuration"
print_status "2. Run: ./scripts/deploy.sh development localnet"
print_status "3. Access the platform at http://localhost:3001"