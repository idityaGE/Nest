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

# Define the kind cluster configuration
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "Creating kind cluster..."
kind create cluster --config kind-config.yaml --name nest-cluster

echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "Building Docker images..."
# Build backend image
cd ../backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# Build frontend image
cd ../frontend
docker build -t nest-frontend:k8s -f docker/Dockerfile.k8s .

echo "Loading images into kind cluster..."
kind load docker-image nest-backend:k8s --name nest-cluster
kind load docker-image nest-frontend:k8s --name nest-cluster
kind load docker-image postgres:16.4 --name nest-cluster

echo "Applying Kubernetes manifests..."
cd ..
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
kubectl apply -f 07-frontend.yaml
kubectl apply -f 08-ingress.yaml

echo "Add the following line to your /etc/hosts file:"
echo "127.0.0.1 nest.local"

echo "Setup completed! You can access the application at http://nest.local"
echo "To load initial data, run: kubectl exec -it deployment/nest-backend -n nest -- make load-data"
echo "To index data, run: kubectl exec -it deployment/nest-backend -n nest -- make index-data"
