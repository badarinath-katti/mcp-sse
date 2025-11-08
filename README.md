# MCP Client-Server Demo

This project demonstrates a Model Context Protocol (MCP) client-server implementation using Spring Boot, containerized with Docker for easy deployment.

## Architecture

- **MCP Client** (Port 8080): Spring Boot application that connects to MCP server and provides REST endpoints for AI-powered interactions
- **MCP Server** (Port 8095): Spring Boot application that implements MCP protocol and provides tools/capabilities to the client

## Services Overview

### MCP Client Service
- Connects to MCP server via SSE (Server-Sent Events)
- Provides REST endpoints for AI chat interactions
- Uses OpenAI integration for natural language processing
- Automatically discovers and uses tools from MCP server

### MCP Server Service  
- Implements MCP protocol for tool discovery and execution
- Provides stock price and company information tools
- Exposes MCP capabilities via standardized protocol
- Runs on WebFlux for reactive programming

## Running the Application

### Prerequisites
- Docker and Docker Compose installed
- Java 17+ (for local development)
- Maven 3.6+ (for local development)
- OpenAI API key (for AI functionality)

### Quick Start (Automated Script)

Use the automated build and cleanup script:
```bash
./build-and-cleanup.sh
```

This script will:
- Build both client and server Maven projects
- Create Docker image with linux/amd64 platform
- Start services in a combined container
- Clean up unnecessary files

### Docker Deployment Options

1. **Combined Service Container** (Recommended):
```bash
./build-and-cleanup.sh
```

2. **Manual Docker Build**:
```bash
# Build both projects
cd client && ./mvnw clean package -DskipTests && cd ..
cd server && ./mvnw clean package -DskipTests && cd ..

# Build and run Docker image
docker build --platform linux/amd64 -f Dockerfile.combined -t mcp-combined .
docker run -d -p 8080:8080 -p 8095:8095 --name mcp-services mcp-combined
```

3. **Push to Registry**:
```bash
REGISTRY_USERNAME=your-username ./push-to-registry.sh
```

### Local Development

1. Build both services:
```bash
cd client && ./mvnw clean package -DskipTests && cd ..
cd server && ./mvnw clean package -DskipTests && cd ..
```

2. Start MCP Server:
```bash
cd server && ./mvnw spring-boot:run
```

3. Start MCP Client (in another terminal):
```bash
cd client && OPENAI_API_KEY=your-api-key ./mvnw spring-boot:run
```

## API Endpoints

### MCP Client Service (http://localhost:8080)

- `GET /1` - Ask "how are you doing?" to AI
- `GET /2` - Ask for SAP company stock price via AI

The client automatically connects to the MCP server and uses available tools to enhance AI responses.

### MCP Server Service (http://localhost:8095)

- Implements MCP protocol endpoints
- Provides tool discovery and execution capabilities
- Available tools:
  - `howsStocks(company)` - Get stock performance information
  - `getStockPrice(company)` - Get current stock price

**Supported Companies:**
- IBM: Stock price and performance data
- MSFT: Microsoft stock information  
- SAP: SAP stock information

## Testing the Services

### Manual Testing

1. **Test MCP Client AI Endpoints:**
```bash
# Simple AI interaction
curl http://localhost:8080/1

# AI with stock price lookup (uses MCP server tools)
curl http://localhost:8080/2
```

2. **Check Service Health:**
```bash
# Test client service
curl -I http://localhost:8080/

# Test server service  
curl -I http://localhost:8095/
```

## Configuration

### Environment Variables

- `OPENAI_API_KEY` - Required for AI functionality in client service
- `REGISTRY_USERNAME` - Docker registry username for image push
- `IMAGE_TAG` - Custom tag for Docker image (default: timestamp)

### Application Properties

Client service (`client/src/main/resources/application.yml`):
```yaml
spring:
  application:
    name: client
```

## Deployment Options

### 1. Combined Container (Default)
Both services run in a single container using supervisord for process management.

### 2. Docker Registry Push
Push the image to Docker Hub or private registry for deployment:
```bash
REGISTRY_USERNAME=your-username ./push-to-registry.sh
```

### 3. Platform-Specific Build
Images are built with `linux/amd64` platform for registry compatibility.

## Docker Container Management

The combined container uses supervisord to manage both services:

- **Client Service**: Runs as `client` program in supervisord
- **Server Service**: Runs as `server` program in supervisord  
- **Logs**: Available at `/tmp/client.out.log` and `/tmp/server.out.log`

## Key Features

- **MCP Protocol**: Implements Model Context Protocol for AI tool integration
- **Reactive Architecture**: Uses Spring WebFlux for non-blocking operations
- **Docker Ready**: Single container deployment with process supervision
- **Registry Compatible**: Platform-specific builds for Docker registries
- **AI Integration**: OpenAI integration with automatic tool discovery
- **Clean Build Process**: Automated build and cleanup scripts

## Scripts Available

- `./build-and-cleanup.sh` - Complete build, image creation, and deployment
- `./push-to-registry.sh` - Push Docker image to registry
- `./start-services.sh` - Service startup and health check script

## Project Structure

```
mcp/
├── client/                 # MCP Client (Spring Boot)
│   ├── src/main/java/com/sap/client/
│   │   ├── ClientApplication.java
│   │   └── SimpleQuestion1.java
│   └── pom.xml
├── server/                 # MCP Server (Spring Boot)  
│   ├── src/main/java/com/sap/server/
│   │   ├── ServerApplication.java
│   │   └── MyService.java
│   └── pom.xml
├── Dockerfile.combined     # Multi-service container
├── supervisord.conf        # Process management
└── build-and-cleanup.sh    # Automated build script
```

## Troubleshooting

### Service Communication Issues
```bash
# Check container logs
docker logs mcp-combined-container

# Check specific service logs
docker exec mcp-combined-container cat /tmp/client.out.log
docker exec mcp-combined-container cat /tmp/server.out.log
```

### Rebuild from Scratch
```bash
# Stop and remove existing container
docker stop mcp-combined-container
docker rm mcp-combined-container

# Rebuild everything
./build-and-cleanup.sh
```

### OpenAI API Key Issues
Ensure your OpenAI API key is properly set:
```bash
# For local development
export OPENAI_API_KEY=your-actual-api-key

# For Docker deployment
docker run -e OPENAI_API_KEY=your-actual-api-key ...
```

## Stopping the Services

```bash
# Stop Docker container
docker stop mcp-combined-container

# Remove container
docker rm mcp-combined-container
```