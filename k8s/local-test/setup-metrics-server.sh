#!/bin/bash

# https://medium.com/@mjkool/metrics-server-in-kubernetes-0ba52352ddcd
# https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43

echo "Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# echo "Patching Metrics Server deployment..."
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# kubectl get apiservices
# kubectl edit deployment metrics-server -n kube-system

echo "Metrics Server will be ready in few moments..."
