#!/bin/bash

set -e

# Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5000'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# Create kind cluster with registry access
echo "Creating Kind cluster..."
kind create cluster --config fixed-kind-config.yaml

# Connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# Apply Kubernetes namespace and config
echo "Creating namespace and configurations..."
kubectl apply -f nest-kubernetes-config.yaml

# Build and push images
echo "Building and pushing backend image..."
docker build -t localhost:5000/nest-backend:latest ./backend -f ./backend/docker/Dockerfile.local
docker push localhost:5000/nest-backend:latest

echo "Building and pushing frontend image..."
docker build -t localhost:5000/nest-frontend:latest ./frontend -f ./frontend/docker/Dockerfile.local
docker push localhost:5000/nest-frontend:latest

# Install ingress controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Apply Kubernetes configurations
echo "Applying database configuration..."
kubectl apply -f db-deployment.yaml

echo "Waiting for database to be ready..."
kubectl wait --namespace nest \
  --for=condition=ready pod \
  --selector=app=nest-db \
  --timeout=120s

echo "Applying backend configuration..."
kubectl apply -f fixed-backend-deployment.yaml

echo "Waiting for backend to be ready..."
kubectl wait --namespace nest \
  --for=condition=ready pod \
  --selector=app=nest-backend \
  --timeout=120s

echo "Applying frontend configuration..."
kubectl apply -f fixed-frontend-deployment.yaml

echo "Applying ingress configuration..."
kubectl apply -f ingress.yaml

echo "Setup complete!"
echo "Add the following line to your /etc/hosts file:"
echo "127.0.0.1 nest.local"
echo "Then access your application at http://nest.local"
