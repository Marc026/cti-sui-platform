#!binbash
# scriptsdeploy.sh
# Main deployment script for CTI Platform

set -e

# Colors for output
RED='033[0;31m'
GREEN='033[0;32m'
YELLOW='033[1;33m'
BLUE='033[0;34m'
NC='033[0m' # No Color

# Configuration
ENVIRONMENT=${1-development}
SUI_NETWORK=${2-localnet}
SKIP_TESTS=${3-false}

echo -e ${BLUE}CTI Platform Deployment Script${NC}
echo -e ${BLUE}===============================${NC}
echo Environment $ENVIRONMENT
echo Sui Network $SUI_NETWORK
echo Skip Tests $SKIP_TESTS
echo 

# Function to print colored output
print_status() {
    echo -e ${GREEN}[INFO]${NC} $1
}

print_warning() {
    echo -e ${YELLOW}[WARNING]${NC} $1
}

print_error() {
    echo -e ${RED}[ERROR]${NC} $1
}

# Function to check if command exists
command_exists() {
    command -v $1 devnull 2&1
}

# Check prerequisites
check_prerequisites() {
    print_status Checking prerequisites...
    
    local missing_commands=()
    
    if ! command_exists sui; then
        missing_commands+=(sui)
    fi
    
    if ! command_exists node; then
        missing_commands+=(node)
    fi
    
    if ! command_exists npm; then
        missing_commands+=(npm)
    fi
    
    if ! command_exists python3; then
        missing_commands+=(python3)
    fi
    
    if ! command_exists docker; then
        missing_commands+=(docker)
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error Missing required commands ${missing_commands[]}
        print_error Please install the missing dependencies and try again.
        exit 1
    fi
    
    print_status All prerequisites satisfied!
}

# Setup environment
setup_environment() {
    print_status Setting up environment...
    
    # Load environment variables
    if [ -f .env ]; then
        export $(cat .env  grep -v '^#'  xargs)
        print_status Loaded environment variables from .env
    else
        print_warning No .env file found. Using default values.
    fi
    
    # Create necessary directories
    mkdir -p logs
    mkdir -p data
    mkdir -p backups
    
    print_status Environment setup complete!
}

# Deploy smart contracts
deploy_smart_contracts() {
    print_status Deploying smart contracts...
    
    cd smart-contractscti_platform
    
    # Build contracts
    print_status Building Move contracts...
    sui move build
    
    # Run tests if not skipped
    if [ $SKIP_TESTS != true ]; then
        print_status Running Move tests...
        sui move test
        
        print_status Running Move Prover...
        sui move prove  print_warning Move Prover completed with warnings
    fi
    
    # Deploy to network
    print_status Deploying to $SUI_NETWORK...
    
    if [ $SUI_NETWORK = localnet ]; then
        # Start local Sui network if needed
        if ! pgrep -f sui start  devnull; then
            print_status Starting local Sui network...
            sui start --with-faucet --force-regenesis &
            sleep 10
        fi
        
        # Fund admin account
        sui client faucet
    fi
    
    # Deploy contracts
    DEPLOY_OUTPUT=$(sui client publish --gas-budget 100000000 --json)
    PACKAGE_ID=$(echo $DEPLOY_OUTPUT  jq -r '.objectChanges[]  select(.type==published)  .packageId')
    
    if [ $PACKAGE_ID = null ]  [ -z $PACKAGE_ID ]; then
        print_error Failed to deploy smart contracts
        exit 1
    fi
    
    print_status Smart contracts deployed successfully!
    print_status Package ID $PACKAGE_ID
    
    # Update environment variables
    echo PACKAGE_ID=$PACKAGE_ID  .....env
    
    cd ....
}

# Build and deploy API
deploy_api() {
    print_status Deploying API service...
    
    cd api
    
    # Install dependencies
    print_status Installing API dependencies...
    npm ci
    
    # Run tests if not skipped
    if [ $SKIP_TESTS != true ]; then
        print_status Running API tests...
        npm test
    fi
    
    # Build API (if build script exists)
    if npm run build devnull 2&1; then
        print_status Building API...
        npm run build
    fi
    
    # Start API service
    if [ $ENVIRONMENT = development ]; then
        print_status Starting API in development mode...
        npm run dev &
        API_PID=$!
        echo $API_PID  ..api.pid
    else
        print_status API ready for production deployment
    fi
    
    cd ..
}

# Build and deploy frontend
deploy_frontend() {
    print_status Deploying frontend...
    
    cd frontend
    
    # Install dependencies
    print_status Installing frontend dependencies...
    npm ci
    
    # Run tests if not skipped
    if [ $SKIP_TESTS != true ]; then
        print_status Running frontend tests...
        npm test
    fi
    
    # Build frontend
    print_status Building frontend...
    npm run build
    
    # Start frontend service
    if [ $ENVIRONMENT = development ]; then
        print_status Starting frontend in development mode...
        npm run dev &
        FRONTEND_PID=$!
        echo $FRONTEND_PID  ..frontend.pid
    else
        print_status Frontend ready for production deployment
    fi
    
    cd ..
}

# Setup database
setup_database() {
    print_status Setting up database...
    
    if [ $ENVIRONMENT = development ]; then
        # Start PostgreSQL with Docker
        docker-compose up -d postgres redis
        
        # Wait for database to be ready
        sleep 5
        
        # Run migrations
        cd api
        npm run migrate
        cd ..
    fi
    
    print_status Database setup complete!
}

# Deploy with Docker
deploy_docker() {
    print_status Deploying with Docker...
    
    if [ $ENVIRONMENT = development ]; then
        docker-compose up -d
    else
        docker-compose -f docker-compose.prod.yml up -d
    fi
    
    print_status Docker deployment complete!
}

# Health check
health_check() {
    print_status Performing health check...
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f httplocalhost3000health devnull 2&1; then
            print_status API health check passed!
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error API health check failed after $max_attempts attempts
            return 1
        fi
        
        print_status Waiting for API to be ready... (attempt $attempt$max_attempts)
        sleep 2
        ((attempt++))
    done
    
    # Check frontend (if running)
    if [ $ENVIRONMENT = development ]; then
        if curl -f httplocalhost3001 devnull 2&1; then
            print_status Frontend health check passed!
        else
            print_warning Frontend health check failed
        fi
    fi
}

# Generate deployment report
generate_report() {
    print_status Generating deployment report...
    
    local timestamp=$(date '+%Y-%m-%d %H%M%S')
    local report_file=deployment-report-$(date '+%Y%m%d-%H%M%S').txt
    
    cat  $report_file  EOF
CTI Platform Deployment Report
==============================
Timestamp $timestamp
Environment $ENVIRONMENT
Sui Network $SUI_NETWORK

Deployment Information
- Package ID ${PACKAGE_ID-Not deployed}
- API Status $(curl -s httplocalhost3000health  jq -r '.status' 2devnull  echo Not available)
- Frontend Status $(curl -s httplocalhost3001 devnull 2&1 && echo Running  echo Not running)

Services
- API httplocalhost3000
- Frontend httplocalhost3001
- Documentation httplocalhost3000docs

Environment Variables
$(env  grep -E '^(SUI_PACKAGE_PLATFORM_NODE_ENV)'  sort)

Docker Containers
$(docker ps --format table {{.Names}}t{{.Status}}t{{.Ports}}  grep cti  echo No containers running)
EOF

    print_status Deployment report saved to $report_file
}

# Cleanup function
cleanup() {
    print_status Cleaning up...
    
    # Kill background processes if they exist
    if [ -f api.pid ]; then
        kill $(cat api.pid) 2devnull  true
        rm api.pid
    fi
    
    if [ -f frontend.pid ]; then
        kill $(cat frontend.pid) 2devnull  true
        rm frontend.pid
    fi
}

# Main deployment flow
main() {
    print_status Starting CTI Platform deployment...
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run deployment steps
    check_prerequisites
    setup_environment
    
    if [ $ENVIRONMENT = docker ]; then
        deploy_docker
    else
        setup_database
        deploy_smart_contracts
        deploy_api
        deploy_frontend
    fi
    
    health_check
    generate_report
    
    print_status Deployment completed successfully!
    print_status API httplocalhost3000
    print_status Frontend httplocalhost3001
    print_status Documentation httplocalhost3000docs
}

# Handle script arguments
case $1 in
    help-h--help)
        cat  EOF
CTI Platform Deployment Script

Usage $0 [environment] [sui_network] [skip_tests]

Arguments
  environment   Deployment environment (developmentproductiondocker) [default development]
  sui_network   Sui network (localnetdevnettestnetmainnet) [default localnet]
  skip_tests    Skip running tests (truefalse) [default false]

Examples
  $0                                    # Deploy to development with localnet
  $0 production testnet                 # Deploy to production with testnet
  $0 docker localnet true              # Deploy with Docker, skip tests

Environment Variables
  Set these in .env file or export them
  - SUI_NETWORK Sui network to use
  - PACKAGE_ID Deployed package ID (set automatically)
  - DATABASE_URL PostgreSQL connection string
  - REDIS_URL Redis connection string
EOF
        exit 0
        ;;
    )
        main
        ;;
esac