#!/bin/bash

# Build, Create Image and Cleanup Script
# This script builds both projects, creates Docker image, and removes unnecessary files

set -e  # Exit on any error

echo "🚀 Starting build and cleanup process..."

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

# Step 1: Stop and remove existing container
print_status "Stopping and removing existing container..."
if docker ps -q -f name=mcp-combined-container | grep -q .; then
    docker stop mcp-combined-container || true
    docker rm mcp-combined-container || true
    print_success "Existing container removed"
else
    print_warning "No existing container found"
fi

# Step 2: Build client project
print_status "Building client project..."
cd client
./mvnw clean package -DskipTests -q
if [ $? -eq 0 ]; then
    print_success "client built successfully"
else
    print_error "Failed to build client"
    exit 1
fi
cd ..

# Step 3: Build server project
print_status "Building server project..."
cd server
./mvnw clean package -DskipTests -q
if [ $? -eq 0 ]; then
    print_success "server built successfully"
else
    print_error "Failed to build server"
    exit 1
fi
cd ..

# Step 4: Create Docker image
print_status "Creating Docker image..."
docker build --platform linux/amd64 -f Dockerfile.combined -t mcp-combined . -q
if [ $? -eq 0 ]; then
    print_success "Docker image created successfully"
else
    print_error "Failed to create Docker image"
    exit 1
fi

# Step 5: Clean up unnecessary files from root folder
print_status "Cleaning up unnecessary files from root folder..."

# List of files/patterns to remove from root folder
CLEANUP_FILES=(
    "*.log"
    "*.tmp"
    "*.cache"
    ".DS_Store"
    "Thumbs.db"
    "docker-compose.render.yml"
    "Dockerfile.proxy"
    "nginx.conf"
    "render.yaml"
    "supervisord-proxy.conf"
    "demo.sh"
    "client.sh"
    "server.sh"
    "run-docker.sh"
)

removed_count=0
for pattern in "${CLEANUP_FILES[@]}"; do
    if ls $pattern 1> /dev/null 2>&1; then
        rm -f $pattern
        print_success "Removed: $pattern"
        ((removed_count++))
    fi
done

# Remove empty directories
if [ -d "logs" ] && [ -z "$(ls -A logs)" ]; then
    rmdir logs
    print_success "Removed empty logs directory"
    ((removed_count++))
fi

if [ $removed_count -eq 0 ]; then
    print_warning "No unnecessary files found to remove"
else
    print_success "Removed $removed_count unnecessary files/directories"
fi

# Step 6: Display final folder structure
print_status "Current root folder structure after cleanup:"
ls -la | grep -E '^d|^-.*\.(sh|yml|yaml|conf|md|jar)$' | head -20

# Step 7: Start new container
print_status "Starting new container..."
docker run -d --name mcp-combined-container -p 8080:8080 -p 8095:8095 mcp-combined
if [ $? -eq 0 ]; then
    print_success "Container started successfully"
    
    # Wait a moment for services to start
    sleep 3
    
    # Check container status
    if docker ps | grep -q mcp-combined-container; then
        print_success "Container is running properly"
        echo ""
        echo "🎉 Build and cleanup completed successfully!"
        echo ""
        echo "Services are now available at:"
        echo "  • client: http://localhost:8080"
        echo "  • server: http://localhost:8095"
        echo ""
        echo "To check logs: docker logs mcp-combined-container"
        echo "To stop:       docker stop mcp-combined-container"
    else
        print_error "Container failed to start properly"
        exit 1
    fi
else
    print_error "Failed to start container"
    exit 1
fi

# Step 8: Summary
echo ""
print_status "=== BUILD SUMMARY ==="
echo "✅ client project built"
echo "✅ server project built" 
echo "✅ Docker image created"
echo "✅ Unnecessary files cleaned up"
echo "✅ Container started and running"
echo ""
print_success "All tasks completed successfully!"