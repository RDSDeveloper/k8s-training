# K8s Learning Project

## Quick Start

```bash
# Start cluster (3 nodes)
minikube start --nodes 3 --driver=docker --memory=5000 --cpus=2

# Build & Deploy
make setup
make build
make deploy

# Test
curl http://localhost:8080/
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/config
```

## Structure

```
apps/          # Application code
kubernetes/    # K8s manifests
  ├── pods/
  ├── deployments/
  ├── services/
  ├── configmaps/
  ├── secrets/
  └── ingress/
terraform/     # Infrastructure as Code
scripts/       # Helper scripts
docs/          # Code examples
```

## Useful Commands

```bash
# Check status
kubectl get all
kubectl get pods -o wide
kubectl get nodes

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>

# Debug
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- sh

# Apply changes
kubectl apply -f kubernetes/...
kubectl rollout restart deployment/<name>
```


