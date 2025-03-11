kind create cluster --name nest --config kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for the ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s


# Create namespace
kubectl create namespace nest

# Apply secrets first
kubectl apply -f secrets/ -n nest

# Apply database components
kubectl apply -f database/ -n nest

# Apply backend components
kubectl apply -f backend/ -n nest

# Apply frontend components
kubectl apply -f frontend/ -n nest

# Apply ingress
kubectl apply -f ingress/ -n nest
