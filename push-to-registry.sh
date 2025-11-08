#!/bin/bash

# Push Docker Image to Registry Script
# This script tags and pushes the mcp-combined image to a Docker registry

set -e  # Exit on any error

echo "🚀 Starting Docker image push to registry..."

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

# Configuration - Update these values for your registry
REGISTRY_URL="${REGISTRY_URL:-docker.io}"  # Default to Docker Hub
REGISTRY_USERNAME="badarinathkatti"
IMAGE_NAME="${IMAGE_NAME:-mcp-combined}"
LOCAL_IMAGE="mcp-combined"

# Get version from environment or use timestamp
if [ -z "$IMAGE_TAG" ]; then
    IMAGE_TAG=$(date +%Y%m%d-%H%M%S)
    print_warning "No IMAGE_TAG provided, using timestamp: $IMAGE_TAG"
fi

# Full image name with registry
FULL_IMAGE_NAME="$REGISTRY_URL/$REGISTRY_USERNAME/$IMAGE_NAME"

# Function to show usage
show_usage() {
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Environment Variables:"
    echo "  REGISTRY_URL        Docker registry URL (default: docker.io)"
    echo "  REGISTRY_USERNAME   Your registry username (required)"
    echo "  IMAGE_NAME          Image name (default: mcp-combined)"
    echo "  IMAGE_TAG           Image tag (default: timestamp)"
    echo "  DOCKER_PASSWORD     Registry password (for non-interactive login)"
    echo ""
    echo "Examples:"
    echo "  # Push to Docker Hub"
    echo "  REGISTRY_USERNAME=myuser ./push-to-registry.sh"
    echo ""
    echo "  # Push to private registry with custom tag"
    echo "  REGISTRY_URL=registry.company.com REGISTRY_USERNAME=myuser IMAGE_TAG=v1.0.0 ./push-to-registry.sh"
    echo ""
    echo "  # Push with automated login"
    echo "  REGISTRY_USERNAME=myuser DOCKER_PASSWORD=mypass ./push-to-registry.sh"
    echo ""
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Validate required variables
if [[ "$REGISTRY_USERNAME" == "your-username" ]]; then
    print_error "REGISTRY_USERNAME must be set!"
    show_usage
    exit 1
fi

# Step 1: Check if local image exists
print_status "Checking if local image '$LOCAL_IMAGE' exists..."
if ! docker image inspect $LOCAL_IMAGE &> /dev/null; then
    print_error "Local image '$LOCAL_IMAGE' not found!"
    print_warning "Please run './build-and-cleanup.sh' first to create the image"
    exit 1
fi
print_success "Local image found"

# Step 2: Docker login (if password provided or interactive)
print_status "Authenticating with registry '$REGISTRY_URL'..."
if [ -n "$DOCKER_PASSWORD" ]; then
    # Non-interactive login
    echo "$DOCKER_PASSWORD" | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin
    if [ $? -eq 0 ]; then
        print_success "Successfully logged in to $REGISTRY_URL"
    else
        print_error "Failed to login to $REGISTRY_URL"
        exit 1
    fi
else
    # Interactive login
    print_warning "No DOCKER_PASSWORD provided, attempting interactive login..."
    docker login $REGISTRY_URL -u $REGISTRY_USERNAME
    if [ $? -eq 0 ]; then
        print_success "Successfully logged in to $REGISTRY_URL"
    else
        print_error "Failed to login to $REGISTRY_URL"
        exit 1
    fi
fi

# Step 3: Tag the image
print_status "Tagging image as '$FULL_IMAGE_NAME:$IMAGE_TAG'..."
docker tag $LOCAL_IMAGE $FULL_IMAGE_NAME:$IMAGE_TAG
if [ $? -eq 0 ]; then
    print_success "Image tagged successfully"
else
    print_error "Failed to tag image"
    exit 1
fi

# Step 4: Tag as latest
print_status "Tagging image as '$FULL_IMAGE_NAME:latest'..."
docker tag $LOCAL_IMAGE $FULL_IMAGE_NAME:latest
if [ $? -eq 0 ]; then
    print_success "Image tagged as latest"
else
    print_error "Failed to tag image as latest"
    exit 1
fi

# Step 5: Push the tagged version
print_status "Pushing image '$FULL_IMAGE_NAME:$IMAGE_TAG' to registry..."
docker push $FULL_IMAGE_NAME:$IMAGE_TAG
if [ $? -eq 0 ]; then
    print_success "Successfully pushed $FULL_IMAGE_NAME:$IMAGE_TAG"
else
    print_error "Failed to push $FULL_IMAGE_NAME:$IMAGE_TAG"
    exit 1
fi

# Step 6: Push the latest version
print_status "Pushing image '$FULL_IMAGE_NAME:latest' to registry..."
docker push $FULL_IMAGE_NAME:latest
if [ $? -eq 0 ]; then
    print_success "Successfully pushed $FULL_IMAGE_NAME:latest"
else
    print_error "Failed to push $FULL_IMAGE_NAME:latest"
    exit 1
fi

# Step 7: Clean up local tags (optional)
read -p "Do you want to remove local registry tags? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing local registry tags..."
    docker rmi $FULL_IMAGE_NAME:$IMAGE_TAG $FULL_IMAGE_NAME:latest 2>/dev/null || true
    print_success "Local registry tags removed"
fi

# Step 8: Display final information
echo ""
print_success "🎉 Image push completed successfully!"
echo ""
echo "📦 Pushed images:"
echo "  • $FULL_IMAGE_NAME:$IMAGE_TAG"
echo "  • $FULL_IMAGE_NAME:latest"
echo ""
echo "🚀 To pull and run the image:"
echo "  docker pull $FULL_IMAGE_NAME:latest"
echo "  docker run -d -p 8080:8080 -p 8095:8095 --name mcp-services $FULL_IMAGE_NAME:latest"
echo ""
echo "🔗 Registry URL: $REGISTRY_URL"
echo "👤 Username: $REGISTRY_USERNAME"
echo "🏷️  Tag: $IMAGE_TAG"
echo ""

# Step 9: Summary
print_status "=== PUSH SUMMARY ==="
echo "✅ Local image verified"
echo "✅ Registry authentication successful"
echo "✅ Image tagged with version and latest"
echo "✅ Image pushed to registry"
echo "✅ Registry push completed"
echo ""
print_success "All tasks completed successfully!"