#!/bin/bash

# https://medium.com/@mjkool/metrics-server-in-kubernetes-0ba52352ddcd
# https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43


kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kubectl get apiservices
# kubectl edit deployment metrics-server -n kube-system

# spec:
#   template:
#     spec:
#       containers:
#       - args:
#         - --cert-dir=/tmp
#         - --secure-port=443
#         - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
#         - --kubelet-use-node-status-port
#         - --metric-resolution=15s
#         - --kubelet-insecure-tls
#         name: metrics-server

# kubectl patch deployment metrics-server -n kube-system --patch "$(cat metric-server-patch.yaml)"

clear
echo "=== Node Metrics ==="
kubectl top nodes
echo

echo "=== Pod Metrics (Top 10 by CPU) ==="
kubectl top pods --all-namespaces --sort-by=cpu | head -11
echo

echo "=== Pod Metrics (Top 10 by Memory) ==="
kubectl top pods --all-namespaces --sort-by=memory | head -11
echo

