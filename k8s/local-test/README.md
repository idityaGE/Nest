# OWASP Nest on Kubernetes with Kind

This document provides instructions for setting up OWASP Nest in a local Kubernetes environment using Kind (Kubernetes IN Docker).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- Sufficient resources on your local machine (at least 4GB RAM, 2 CPU cores)

## Directory Structure

```
k8s/
├── local-test/
│   ├── 00-kind-config.yaml
│   ├── 01-namespace.yaml
│   ├── 02-configmaps.yaml
│   ├── 03-secrets.yaml
│   ├── 04-persistent-volumes.yaml
│   ├── 05-db.yaml
│   ├── 06-backend.yaml
│   ├── 07-frontend.yaml
│   ├── 08-ingress.yaml
│   ├── setup-kind.sh
│   ├── cleanup-kind.sh
│   └── README.md
```

## Quick Start

### Setup

1. Run the setup script:

```bash
cd k8s/local-test
chmod +x setup-kind.sh
./setup-kind.sh
```

2. Configure DNS for host access:

```bash
# In WSL, add to /etc/hosts:
sudo sh -c 'echo "127.0.0.1 nest.local" >> /etc/hosts'

# In Windows, add to C:\Windows\System32\drivers\etc\hosts:
# Get WSL IP first
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# Add this IP with nest.local to Windows hosts file
```

3. Access the application:

- Frontend: http://nest.local
- API: http://nest.local/api/v1/
- GraphQL: http://nest.local/graphql/

### Cleanup

```bash
./cleanup-kind.sh
```

## Managing Deployments

### Updating Backend Image

#### Option 1: Simple Rollout Restart

```bash
# Rebuild the backend image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# Load into kind
kind load docker-image nest-backend:k8s --name nest-cluster

# Restart deployment
kubectl -n nest rollout restart deployment/nest-backend
```

#### Option 2: Scale Down/Up

```bash
# Stop deployment
kubectl -n nest scale deployment nest-backend --replicas=0

# Rebuild and load image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .
kind load docker-image nest-backend:k8s --name nest-cluster

# Start deployment
kubectl -n nest scale deployment nest-backend --replicas=1
```

#### Option 3: Delete and Reapply

```bash
# Delete deployment
kubectl -n nest delete -f k8s/local-test/06-backend.yaml

# Rebuild and load image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .
kind load docker-image nest-backend:k8s --name nest-cluster

# Reapply deployment
kubectl apply -f k8s/local-test/06-backend.yaml
```

## Useful Commands

### Monitoring and Debugging

```bash
# View logs
kubectl logs -f -l app=nest-backend -n nest
kubectl logs -f -l app=nest-frontend -n nest
kubectl logs -f -l app=nest-db -n nest

# View pod status
kubectl get pods -n nest

# Describe resources
kubectl describe pod [pod-name] -n nest
kubectl describe deployment nest-backend -n nest

# Set default namespace
kubectl config set-context --current --namespace=nest
```

### Accessing Containers

```bash
# Execute shell in container
kubectl exec -it deployment/nest-backend -n nest -- /bin/bash

# Run commands directly
kubectl exec -it deployment/nest-backend -n nest -- python manage.py shell
```

### Cleanup Commands

```bash
# Delete specific pod (will be recreated)
kubectl delete pod [pod-name] -n nest

# Delete all pods in all namespaces
kubectl delete pods --all --all-namespaces

# Delete cluster
kind delete cluster --name nest-cluster
```

## Troubleshooting

### Network Issues

If you're running in WSL2, you need to:

1. Add `127.0.0.1 nest.local` to WSL's hosts
2. Add your WSL2 IP followed by `nest.local` to Windows hosts file `C:\Windows\System32\drivers\etc\hosts`
3. Ensure ports 80 and 443 are accessible from Windows

### Database Connection Issues

If the backend can't connect to the database:

1. Check if database pod is running: `kubectl get pods -n nest`
2. View database logs: `kubectl logs -n nest -l app=nest-db`
3. Ensure backend environment variables match database service name

```bash
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# Example output: 172.28.135.112
```
Update your Windows hosts file again:
`172.28.135.112 nest.local`


### Image Loading Issues

If images aren't loading properly:

```bash
# Verify images are loaded
kind get clusters
docker exec -it nest-cluster-control-plane crictl images
```

### Volume Issues

For persistent volume problems, consider using emptyDir for testing:

```yaml
volumes:
- name: postgres-data
  emptyDir: {}
```

### Port Forwarding
```bash
# Start frontend port forwarding
kubectl port-forward -n nest svc/nest-frontend 3000:3000 --address 0.0.0.0 &
echo "Frontend available at http://localhost:3000"
# Start backend port forwarding
kubectl port-forward -n nest svc/nest-backend 8000:8000 --address 0.0.0.0 &
echo "Backend available at http://localhost:8000"

# Stop port forwarding
jobs
kill %1
kill %2
```

## Notes

This setup is for development purposes only. For production, implement:
- Proper secrets management
- SSL/TLS encryption
- Resource limits
- Monitoring and logging
- High-availability configurations

Similar code found with 1 license type
