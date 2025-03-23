#!/bin/bash

set -e

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "kind is not installed. Please install it first: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install it first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Please install it first: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "Creating kind cluster..."
kind create cluster --config 00-kind-config.yaml --name nest-cluster

echo "Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.publishService.enabled=true \
  --set controller.hostNetwork=true

echo "Waiting for NGINX Ingress Controller to be ready..."
sleep 5
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || echo "Warning: Ingress controller not ready yet, but continuing..."

echo "Checking ingress controller status:"
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo "Giving additional time for webhook initialization..."
sleep 5

echo "Building Docker images..."
# Build backend image
cd ../../backend/
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# Build frontend image
cd ../frontend/
docker build -t nest-frontend:k8s -f docker/Dockerfile.k8s .

# Pull postgres:16.4 if not present locally
docker pull postgres:16.4

echo "Loading images into kind cluster..."
kind load docker-image nest-backend:k8s --name nest-cluster
kind load docker-image nest-frontend:k8s --name nest-cluster
kind load docker-image postgres:16.4 --name nest-cluster

echo "Applying Kubernetes manifests..."
cd ../k8s/local-test
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmaps.yaml
kubectl apply -f 03-secrets.yaml
kubectl apply -f 04-persistent-volumes.yaml
kubectl apply -f 05-db.yaml

echo "Waiting for database to be ready..."
kubectl wait --namespace nest \
  --for=condition=ready pod \
  --selector=app=nest-db \
  --timeout=120s

kubectl apply -f 06-backend.yaml

echo "Waiting for backend to be ready (data loading & indexing)..."
echo "This might take up to 10 minutes..."
echo ""
echo "TIP: To watch initialization progress in real-time, run this in a separate terminal:"
echo "     kubectl logs -f -l app=nest-backend -n nest"
echo ""

kubectl wait --namespace nest \
  --for=condition=ready pod \
  --selector=app=nest-backend \
  --timeout=600s || true

# Show pod status
kubectl get pods -n nest

kubectl apply -f 07-frontend.yaml

echo "Waiting for frontend to be ready..."
kubectl wait --namespace nest \
  --for=condition=ready pod \
  --selector=app=nest-frontend \
  --timeout=100s

kubectl apply -f 08-ingress.yaml

echo "Adding entries to /etc/hosts file (requires sudo)..."
grep -q "nest.frontend" /etc/hosts || sudo sh -c 'echo "127.0.0.1 nest.frontend" >> /etc/hosts'
grep -q "nest.backend" /etc/hosts || sudo sh -c 'echo "127.0.0.1 nest.backend" >> /etc/hosts'

echo "---------------------------------------"
echo "Setup complete! Access the application:"
echo "Frontend: http://nest.frontend/"
echo "Backend API: http://nest.backend/api/v1/"
echo "GraphQL: http://nest.backend/graphql/"
echo "IDX: http://nest.backend/idx/"
echo "---------------------------------------"
echo "To check pod status: kubectl get pods -n nest"
echo "To check logs: kubectl logs -n nest -l app=nest-backend"

echo "To close everything run: './cleanup-kind.sh'"
