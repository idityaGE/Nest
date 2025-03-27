#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables for customization
NAMESPACE="monitoring"
PROMETHEUS_NODEPORT=30000
GRAFANA_NODEPORT=31000
GRAFANA_LOCAL_PORT=3001
PROMETHEUS_LOCAL_PORT=9090

# Create the monitoring namespace
echo "Creating namespace: $NAMESPACE..."
kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."

# Add the Prometheus Helm repository
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Install the Prometheus and Grafana stack
echo "Installing Prometheus and Grafana stack..."
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=$PROMETHEUS_NODEPORT \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=$GRAFANA_NODEPORT

# Wait for pods to be ready
echo "Waiting for pods to be ready in namespace: $NAMESPACE..."
kubectl --namespace $NAMESPACE wait --for=condition=ready pod -l "release=prometheus-stack" --timeout=300s

# Display the list of services
echo "Listing services in namespace: $NAMESPACE..."
kubectl -n $NAMESPACE get svc

# Port-forward Prometheus and Grafana services
echo "Setting up port-forwarding for Prometheus and Grafana..."
kubectl port-forward svc/prometheus-stack-kube-prom-prometheus $PROMETHEUS_LOCAL_PORT:9090 -n $NAMESPACE &
kubectl port-forward svc/prometheus-stack-grafana $GRAFANA_LOCAL_PORT:80 -n $NAMESPACE &

# Retrieve Grafana admin password
echo "Retrieving Grafana admin password..."
GRAFANA_PASSWORD=$(kubectl --namespace $NAMESPACE get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d)
echo "Grafana admin password: $GRAFANA_PASSWORD"

# Display access information
echo -e "\nAccess Prometheus at: http://localhost:$PROMETHEUS_LOCAL_PORT"
echo "Access Grafana at: http://localhost:$GRAFANA_LOCAL_PORT"
echo "Use the above password to log in to Grafana (username: admin)."
