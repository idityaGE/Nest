# OWASP Nest on Kubernetes with kind

This directory contains Kubernetes manifests and scripts to run OWASP Nest locally using kind (Kubernetes IN Docker).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- Sufficient resources on your local machine (at least 4GB RAM, 2 CPU cores)

## Directory Structure

```
k8s/
├── 01-namespace.yaml
├── 02-configmaps.yaml
├── 03-secrets.yaml
├── 04-persistent-volumes.yaml
├── 05-db.yaml
├── 06-backend.yaml
├── 07-frontend.yaml
├── 08-ingress.yaml
├── setup-kind.sh
├── cleanup-kind.sh
└── README.md
```

## Setup Instructions

1. Clone the OWASP Nest repository:

```bash
git clone https://github.com/<your-account>/<nest-fork>
cd <nest-fork>
```

2. Create a new directory for Kubernetes files and copy all the YAML files and scripts:

```bash
mkdir -p k8s
# Copy all the YAML files and scripts to the k8s directory
```

3. Update the secrets in `03-secrets.yaml` with your own values:

- `DJANGO_SECRET_KEY`: Generate a random secret key
- `DJANGO_ALGOLIA_APPLICATION_ID`: Your Algolia application ID
- `DJANGO_ALGOLIA_WRITE_API_KEY`: Your Algolia write API key

4. Make the scripts executable:

```bash
chmod +x k8s/setup-kind.sh
chmod +x k8s/cleanup-kind.sh
```

5. Run the setup script:

```bash
cd k8s
./setup-kind.sh
```

6. Update your `/etc/hosts` file to add the entry:

```
127.0.0.1 nest.local
```

7. Access the application:

- Frontend: http://nest.local
- Backend API: http://nest.local/api/v1/
- GraphQL: http://nest.local/graphql/

8. Load initial data and index it:

```bash
kubectl exec -it deployment/nest-backend -n nest -- make load-data
kubectl exec -it deployment/nest-backend -n nest -- make index-data
```

## Cleanup Instructions

To delete all resources and the kind cluster, run:

```bash
./cleanup-kind.sh
```

## Troubleshooting

### 1. Images not loading into kind cluster

If you encounter issues with loading images into the kind cluster, you can try building them directly inside the cluster:

```bash
# For backend
docker exec -it nest-cluster-control-plane bash -c "cd /home/owasp && docker build -t nest-backend:local -f docker/Dockerfile.local ."

# For frontend
docker exec -it nest-cluster-control-plane bash -c "cd /home/owasp && docker build -t nest-frontend:local -f docker/Dockerfile.local ."
```

### 2. Database connection issues

If the backend can't connect to the database, check if the database pod is running and ready:

```bash
kubectl get pods -n nest
```

You can also check the logs:

```bash
kubectl logs -n nest deployment/nest-db
kubectl logs -n nest deployment/nest-backend
```

### 3. Volume mounting issues

If you encounter issues with persistent volumes, you can use emptyDir for testing:

```yaml
volumes:
- name: postgres-data
  emptyDir: {}
```

Note that this will lose data when the pod is deleted.

## Notes

- This setup is for local development only. For production, you would need to:
  - Use a proper database with persistent storage
  - Configure proper secrets management
  - Set up SSL/TLS
  - Configure resource limits and requests
  - Set up monitoring and logging


---

### Some Extra Notes

#### Option 2: Rollout Restart (Simpler)
# 1. Rebuild the image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# 2. Load the new image into kind
kind load docker-image nest-backend:k8s --name nest-cluster

# 3. Rollout restart (this will recreate the pods with the new image)
kubectl -n nest rollout restart deployment/nest-backend


#### Option 1: Full Replacement Process
# 1. Stop the deployment
kubectl -n nest scale deployment nest-backend --replicas=0

# 2. Rebuild the image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# 3. Load the new image into kind
kind load docker-image nest-backend:k8s --name nest-cluster

# 4. Restart the deployment
kubectl -n nest scale deployment nest-backend --replicas=1


#### Option 3: Delete & Reapply
# 1. Delete the deployment
kubectl -n nest delete -f k8s/staging/06-backend.yaml

# 2. Rebuild the image
cd /home/adii/Desktop/GSoC2025/Nest/backend
docker build -t nest-backend:k8s -f docker/Dockerfile.k8s .

# 3. Load the new image into kind
kind load docker-image nest-backend:k8s --name nest-cluster

# 4. Reapply the deployment
kubectl apply -f k8s/staging/06-backend.yaml





### Solution for network 
```bash
adii@Virus:~/Desktop/GSoC2025/Nest/k8s/staging$ sudo su
[sudo] password for adii: 
root@Virus:/home/adii/Desktop/GSoC2025/Nest/k8s/staging# vim /etc/hosts

# add this line "127.0.0.1 nest.local"

# Get the WSL2 IP address:
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# Example output: 172.28.135.112

# Open C:\Windows\System32\drivers\etc\hosts
# Update your Windows hosts file again:
172.28.135.112 nest.local
```
