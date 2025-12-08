# Production Deployment Guide

## Server Steps

### 1. Server Preparation

```bash
# SSH connection to server
ssh user@your-server.com

# System update
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
# Restart SSH session after this command
```

### 2. Traefik Installation

```bash
# Create Traefik network
sudo docker network create web

# Configure Traefik (refer to Traefik documentation)
sudo mkdir -p /opt/traefik
cd /opt/traefik

# Start Traefik
sudo docker-compose up -d
```

### 3. MASLDatlas Deployment

```bash
# Clone project
cd /opt
sudo git clone https://github.com/BioMAs/MASLDatlas.git
sudo chown -R $USER:$USER MASLDatlas
cd MASLDatlas

# Automatic deployment
chmod +x scripts/deploy-prod.sh
./scripts/deploy-prod.sh
```

## 4. Verification

### Check Services

```bash
# Container status
docker-compose -f docker-compose.prod.yml ps

# Application logs
docker-compose -f docker-compose.prod.yml logs -f masldatlas

# Traefik logs
cd /opt/traefik && docker-compose logs -f traefik
```

### Test Application

```bash
# Local test
curl -f http://localhost:3838

# Test via Traefik
curl -f https://your-domain.com
```

## 5. Useful Commands

### Restart

```bash
# Restart application
docker-compose -f docker-compose.prod.yml restart

# Restart with rebuild
docker-compose -f docker-compose.prod.yml up -d --build
```

### Monitoring

```bash
# Resource usage
docker stats

# Disk space
df -h
```
