#!/bin/bash

set -e

echo "Applying Kubernetes Dashboard from official source..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo "Applying Kubernetes Dashboard..."
kubectl apply -f 09-k8s-dashboard.yaml

echo "Waiting for dashboard to be ready..."
kubectl wait --namespace kubernetes-dashboard \
  --for=condition=ready pod \
  --selector=k8s-app=kubernetes-dashboard \
  --timeout=90s || echo -e "Timeout\n Warning: Dashboard pods not ready in time, but continuing..."

echo "Creating dashboard access token..."
echo ""
kubectl -n kubernetes-dashboard create token admin-user
echo ""

echo "Starting dashboard proxy..."
echo "Dashboard will be available at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo "Use the token printed above to log in."
echo "Press Ctrl+C to stop the proxy when done."
kubectl proxy &
