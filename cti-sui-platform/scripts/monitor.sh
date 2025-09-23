set -e

echo "CTI Platform Monitoring"
echo "======================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check API health
check_api() {
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        print_status "API service is healthy"
    else
        print_error "API service is not responding"
    fi
}

# Check Frontend
check_frontend() {
    if curl -f http://localhost:3001 >/dev/null 2>&1; then
        print_status "Frontend is accessible"
    else
        print_warning "Frontend is not accessible"
    fi
}

# Check database
check_database() {
    if docker ps | grep postgres >/dev/null 2>&1; then
        print_status "Database container is running"
    else
        print_warning "Database container is not running"
    fi
}

# Check Redis
check_redis() {
    if docker ps | grep redis >/dev/null 2>&1; then
        print_status "Redis container is running"
    else
        print_warning "Redis container is not running"
    fi
}

# Check disk space
check_disk_space() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $usage -lt 80 ]; then
        print_status "Disk usage is normal ($usage%)"
    elif [ $usage -lt 90 ]; then
        print_warning "Disk usage is high ($usage%)"
    else
        print_error "Disk usage is critical ($usage%)"
    fi
}

# Check memory usage
check_memory() {
    local usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ $usage -lt 80 ]; then
        print_status "Memory usage is normal ($usage%)"
    elif [ $usage -lt 90 ]; then
        print_warning "Memory usage is high ($usage%)"
    else
        print_error "Memory usage is critical ($usage%)"
    fi
}

# Main monitoring checks
echo "Checking services..."
check_api
check_frontend
check_database
check_redis

echo ""
echo "Checking system resources..."
check_disk_space
check_memory

echo ""
echo "Monitoring completed at $(date)"