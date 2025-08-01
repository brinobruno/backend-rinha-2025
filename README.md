# Pit - Optimized Payment Processing Backend

## Architecture Overview

This is an optimized Elixir/Phoenix backend for the Rinha de Backend 2025 challenge, designed to maximize profit while ensuring zero inconsistencies.

## Key Optimizations

### 1. Redis-Based Caching
- **Processor Status**: Uses Redis to cache processor health status with 60-second expiration
- **Payment Caching**: Caches successful payments in Redis for consistency checks
- **Retry Queue**: Implements Redis-based retry mechanism for failed payments

### 2. Async Processing
- **Non-blocking Payments**: Payment processing is asynchronous to avoid blocking HTTP responses
- **Database Writes**: Database persistence happens asynchronously after successful payment processing
- **Concurrent Health Checks**: Processor health checks run concurrently for better performance

### 3. Optimized Processor Selection
- **Smart Routing**: Uses processor response times to select the fastest available processor
- **Fallback Strategy**: Automatically falls back to slower processors when faster ones are unavailable
- **Health Monitoring**: Continuous monitoring with 5-second intervals (respecting API rate limits)

### 4. Resource Optimization
- **Finch Pool**: Increased HTTP client pool size to 200 for better concurrency
- **Database Pool**: Optimized database connection pool for better throughput
- **Memory Management**: Efficient resource allocation across services

### 5. Load Balancing
- **Nginx Configuration**: Optimized nginx with aggressive timeouts and fast failover
- **Multiple App Instances**: Two Phoenix applications for load distribution
- **Redis Caching**: Shared Redis instance for cross-instance data consistency

## Performance Features

### Fast Response Times
- **Async Processing**: HTTP responses return immediately while processing continues
- **Optimized Timeouts**: Carefully tuned timeouts for different scenarios
- **Connection Pooling**: Efficient HTTP and database connection management

### Consistency Guarantees
- **Dual Storage**: Payments stored in both Redis cache and PostgreSQL database
- **Summary Reconciliation**: Combines data from both sources for accurate summaries
- **Retry Mechanism**: Failed payments are automatically retried up to 3 times

### Fault Tolerance
- **Health Monitoring**: Continuous monitoring of payment processors
- **Automatic Failover**: Seamless switching between processors based on health
- **Error Recovery**: Comprehensive error handling and recovery mechanisms

## Technology Stack

- **Backend**: Elixir/Phoenix
- **Database**: PostgreSQL
- **Cache**: Redis
- **Load Balancer**: Nginx
- **HTTP Client**: Finch
- **Containerization**: Docker Compose

## Resource Allocation

Total resource usage within limits:
- **CPU**: 1.45 cores (out of 1.5 limit)
- **Memory**: 350MB (at limit)

### Service Breakdown:
- **Nginx**: 0.15 CPU, 30MB RAM
- **Redis**: 0.25 CPU, 60MB RAM  
- **PostgreSQL**: 0.35 CPU, 100MB RAM
- **App1**: 0.35 CPU, 80MB RAM
- **App2**: 0.35 CPU, 80MB RAM

## Expected Performance

Based on the optimizations:
- **P99 Response Time**: Target < 10ms for performance bonus
- **Throughput**: High transaction processing with async handling
- **Consistency**: Zero inconsistencies through dual storage and reconciliation
- **Profit Maximization**: Smart processor selection for lowest fees

## Running the Application

```bash
# Start payment processors first
docker-compose -f ../payment-processor/docker-compose.yml up -d

# Start the application
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Monitoring

The application provides comprehensive logging for:
- Processor health status changes
- Payment processing success/failure
- Retry queue processing
- Performance metrics

## Architecture Diagram

```
Client Request → Nginx → App1/App2 → Redis Cache → Payment Processor
                                    ↓
                              PostgreSQL DB
```

This architecture ensures high performance, zero inconsistencies, and maximum profit through intelligent processor selection and efficient resource utilization.

