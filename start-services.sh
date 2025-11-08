#!/bin/bash

# Wait for services to be ready
echo "Starting MCP services..."

# Start supervisord in background
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

# Wait for server service to be ready (on port 8095)
echo "Waiting for server service to start on port 8095..."
while ! curl -f http://localhost:8095/ > /dev/null 2>&1; do
    sleep 2
    echo "Still waiting for server service..."
done

echo "MCP Server service is ready!"

# Wait for client service to be ready (on port 8080)
echo "Waiting for client service to start on port 8080..."
while ! curl -f http://localhost:8080/ > /dev/null 2>&1; do
    sleep 2
    echo "Still waiting for client service..."
done

echo "MCP Client service is ready!"
echo "Both MCP services are running successfully!"

# Keep the container running
wait