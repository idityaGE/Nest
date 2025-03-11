#!/bin/bash

# Create a local Docker registry
docker run -d -p 5000:5000 --restart=always --name kind-registry registry:2

# Connect to the registry
# This creates a network if not already created
docker network connect kind kind-registry || {
  # If the kind network doesn't exist yet, create it
  docker network create kind
  docker network connect kind kind-registry
}

# Build and push images to local registry
# Backend
cd backend
docker build -t localhost:5000/nest-backend:latest -f docker/Dockerfile.local .
docker push localhost:5000/nest-backend:latest
cd ..

# Frontend
cd frontend
docker build -t localhost:5000/nest-frontend:latest -f docker/Dockerfile.local .
docker push localhost:5000/nest-frontend:latest
cd ..
