kind create cluster --config kind-config.yaml

# Build backend image
docker build -t nest-backend:local -f backend/docker/Dockerfile.local backend/

# Build frontend image
docker build -t nest-frontend:local -f frontend/docker/Dockerfile.local frontend/

# Load images into kind
kind load docker-image nest-backend:local --name nest
kind load docker-image nest-frontend:local --name nest


kubectl apply -f nest-kubernetes-config.yaml
kubectl apply -f db-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl apply -f ingress.yaml





-------

kubectl get pods
kubectl logs <pod-name>

kubectl config set-context --current --namespace=<namespace>

kubectl describe pod nest-backend-656db99c8b-2wzgg -n nest

kubectl delete pod nest-backend-656db99c8b-2wzgg -n nest


kubectl delete pods --all --all-namespaces

kind delete cluster


so the problem I am facing is related to volume mount casue I am using wsl and my docker desktop is in windows.
