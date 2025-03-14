#!/bin/bash
set -e

echo "Deleting kind cluster..."
kind delete cluster --name nest-cluster

echo "Cleanup completed!"
