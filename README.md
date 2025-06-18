# Tarantool Key-Value Storage

This repository contains the source code for a simple *key-value* storage built on *Tarantool 3.x*. The project demonstrates how to create a sharded key-value store with TTL support, Prometheus metrics, and Docker deployment.

## Features
- Key-value storage with CRUD operations.
- Support for TTL (Time To Live) for automatic record expiration.
- Prefix-based key search.
- Sharding using *vshard*.
- Prometheus metrics export.
- Dockerized deployment with *Docker Compose*.

## Requirements
- **Docker** and **Docker Compose** for deployment.
- **Tarantool 3.x** (installed in the Docker image).
- **tt** CLI (included in the Docker image, but can be installed locally for manual interaction).

## Project Structure
```
├── Dockerfile          # Docker image configuration
├── docker-compose.yml  # Docker Compose setup
├── tt_kv/              # Tarantool application
│   ├── config.yaml     # Cluster configuration
│   ├── instances.yml   # Instance definitions
│   ├── router.lua      # Router logic
│   ├── storage.lua     # Storage logic
│   └── tt_kv-scm-1.rockspec # Dependencies
└── README.md           # This file
```

## Installation and Setup

### 1. Clone the Repository
```bash
git clone https://github.com/MaratKarimov/tt_kv.git
cd tt_kv
```

### 2. Deploy the Tarantool Cluster
Build and start the Tarantool cluster using Docker Compose:
```bash
docker compose rm -f
docker compose up --build -d
```

Verify the cluster is running:
```bash
docker ps
```
You should see a container named `tt_kv-tarantool-1` with port `3303` mapped.

### 3. Check Cluster Status
Confirm the *vshard* cluster is operational:
```bash
docker exec tt_kv-tarantool-1 /bin/sh -c "echo \"vshard.router.info()\" | tt connect -x yaml \"tt_kv:router-001-a\""
```
This command outputs the router's status and bucket distribution.

## Working with the Storage

### Inserting Data
1. **Insert a non-expiring record** (`test0 = test1`):
   ```bash
   docker exec tt_kv-tarantool-1 /bin/sh -c "echo \"crud.insert_object('key_value', {key = 'test0', value = 'test1', expire_at = 0})\" | tt connect -x yaml \"tt_kv:router-001-a\""
   ```

2. **Insert a record with 5-second TTL** (`test2 = test3`):
   ```bash
   docker exec tt_kv-tarantool-1 /bin/sh -c "echo \"crud.insert_object('key_value', {key = 'test2', value = 'test3', expire_at = require('os').time() + 5})\" | tt connect -x yaml \"tt_kv:router-001-a\""
   ```

### Reading Data
To manually read data, connect to the router instance:
```bash
docker exec -it tt_kv-tarantool-1 tt connect -u app -p app "tt_kv:router-001-a"
```
Then run:
```lua
crud.select('key_value', {{'key', '=', 'test0'}})
```