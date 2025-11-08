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

# Check if OPENAI_API_KEY is set and not empty
if [ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "" ]; then
    print_success "Using provided OPENAI_API_KEY environment variable"
    docker run -d --name mcp-combined-container \
        -p 8080:8080 \
        -p 8095:8095 \
        -e OPENAI_API_KEY="$OPENAI_API_KEY" \
        -e MCP_SERVER_URL="http://localhost:8095" \
        mcp-combined
else
    print_warning "No OPENAI_API_KEY provided. Client service AI features will not work."
    print_warning "To use OpenAI features, run with:"
    print_warning "  OPENAI_API_KEY=sk-your-key ./build-and-cleanup.sh"
    docker run -d --name mcp-combined-container \
        -p 8080:8080 \
        -p 8095:8095 \
        -e MCP_SERVER_URL="http://localhost:8095" \
        mcp-combined
fi

if [ $? -eq 0 ]; then
    print_success "Container started successfully"
    
    # Wait for services to start
    print_status "Waiting for services to initialize..."
    sleep 5
    
    # Check container status
    if docker ps | grep -q mcp-combined-container; then
        print_success "Container is running properly"
        
        # Test if services are responding
        print_status "Testing service connectivity..."
        if curl -s -f http://localhost:8080/ > /dev/null 2>&1; then
            print_success "Client service is responding on port 8080"
        else
                print_warning "Client service may still be starting up"
        fi
        
        if curl -s -f http://localhost:8095/ > /dev/null 2>&1; then
            print_success "Server service is responding on port 8095"
        else
            print_warning "Server service may still be starting up"
        fi
        
        echo ""
        echo "🎉 Build and cleanup completed successfully!"
        echo ""
        echo "Services are now available at:"
        echo "  • Client (MCP Client): http://localhost:8080"
        echo "    - GET /1 - Ask AI 'how are you doing?'"
        echo "    - GET /2 - Ask AI for SAP stock price"
        echo "    - GET /env - Check environment variables"
        echo "  • Server (MCP Server): http://localhost:8095"
        echo ""
        
        if [ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "" ]; then
            echo "✅ OpenAI API key configured - AI endpoints should work"
            echo "   Test with: curl http://localhost:8080/1"
            echo "   Check env: curl http://localhost:8080/env/OPENAI_API_KEY"
        else
            echo "⚠️  No OpenAI API key configured"
            echo "   AI endpoints will show authentication errors"
            echo "   To fix: OPENAI_API_KEY=sk-your-key ./build-and-cleanup.sh"
            echo "   Check env: curl http://localhost:8080/env/OPENAI_API_KEY"
        fi
        echo ""
        echo "Useful commands:"
        echo "  Check logs:  docker logs mcp-combined-container"
        echo "  Stop:        docker stop mcp-combined-container"
        echo "  Restart:     docker restart mcp-combined-container"
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