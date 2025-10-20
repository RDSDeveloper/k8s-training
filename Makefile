.PHONY: help build deploy clean restart logs test

help:
	@echo "European Cities & Barbarian Invasions - K8s Project"
	@echo ""
	@echo "Available commands:"
	@echo "  make build    - Build Docker images"
	@echo "  make deploy   - Deploy all resources to K8s"
	@echo "  make restart  - Restart deployments"
	@echo "  make logs     - View logs"
	@echo "  make test     - Test endpoints"
	@echo "  make clean    - Delete all resources"

build:
	@echo "🔨 Building Docker images..."
	@echo ""
	@echo "Building backend (FastAPI)..."
	docker build -t localhost:5000/invasions-backend:v1 apps/backend/
	minikube image load localhost:5000/invasions-backend:v1
	@echo ""
	@echo "Building frontend (Nginx)..."
	docker build -t localhost:5000/invasions-frontend:v1 apps/frontend/
	minikube image load localhost:5000/invasions-frontend:v1
	@echo ""
	@echo "✅ Images built and loaded"

deploy:
	@echo "🚀 Deploying to Kubernetes..."
	@echo ""
	@echo "1. Creating storage..."
	kubectl apply -f kubernetes/storage/
	@echo ""
	@echo "2. Creating ConfigMaps..."
	kubectl apply -f kubernetes/configmaps/
	@echo ""
	@echo "3. Creating Secrets..."
	kubectl apply -f kubernetes/secrets/
	@echo ""
	@echo "4. Deploying PostgreSQL..."
	kubectl apply -f kubernetes/statefulsets/
	@echo "   Waiting for PostgreSQL to be ready..."
	kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
	@echo ""
	@echo "5. Deploying Backend API..."
	kubectl apply -f kubernetes/deployments/backend-deployment.yaml
	kubectl apply -f kubernetes/services/backend-service.yaml
	kubectl apply -f kubernetes/services/postgres-service.yaml
	@echo ""
	@echo "6. Deploying Frontend..."
	kubectl apply -f kubernetes/deployments/frontend-deployment.yaml
	kubectl apply -f kubernetes/services/frontend-service.yaml
	@echo ""
	@echo "7. Configuring Ingress..."
	kubectl apply -f kubernetes/ingress/
	@echo ""
	@echo "⏳ Waiting for all pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=backend --timeout=60s || true
	kubectl wait --for=condition=ready pod -l app=frontend --timeout=60s || true
	@echo ""
	@echo "✅ Deployment complete!"
	@echo ""
	@echo "🌐 Access the app:"
	@echo "   Run: minikube service ingress-nginx-controller -n ingress-nginx"
	@echo "   Or: kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80"

restart:
	@echo "♻️  Restarting deployments..."
	kubectl rollout restart deployment/backend-deployment
	kubectl rollout restart deployment/frontend-deployment
	kubectl rollout status deployment/backend-deployment
	kubectl rollout status deployment/frontend-deployment
	@echo "✅ Restarted"

logs:
	@echo "📜 Recent logs:"
	@echo ""
	@echo "=== Backend logs ==="
	kubectl logs -l app=backend --tail=20
	@echo ""
	@echo "=== Frontend logs ==="
	kubectl logs -l app=frontend --tail=20
	@echo ""
	@echo "=== PostgreSQL logs ==="
	kubectl logs -l app=postgres --tail=20

test:
	@echo "🧪 Testing endpoints..."
	@echo ""
	@echo "Backend health:"
	@kubectl exec -it deployment/backend-deployment -- curl -s http://localhost:8000/health | head -20
	@echo ""
	@echo ""
	@echo "Cities API:"
	@kubectl exec -it deployment/backend-deployment -- curl -s http://localhost:8000/api/cities | head -50
	@echo "..."

clean:
	@echo "🗑️  Deleting all resources..."
	kubectl delete -f kubernetes/ingress/ --ignore-not-found=true
	kubectl delete -f kubernetes/services/ --ignore-not-found=true
	kubectl delete -f kubernetes/deployments/ --ignore-not-found=true
	kubectl delete -f kubernetes/statefulsets/ --ignore-not-found=true
	kubectl delete -f kubernetes/storage/ --ignore-not-found=true
	kubectl delete -f kubernetes/configmaps/ --ignore-not-found=true
	kubectl delete -f kubernetes/secrets/ --ignore-not-found=true
	@echo "✅ Cleaned"

status:
	@echo "📊 Cluster Status"
	@echo ""
	@echo "Pods:"
	@kubectl get pods
	@echo ""
	@echo "Services:"
	@kubectl get services
	@echo ""
	@echo "Ingress:"
	@kubectl get ingress
	@echo ""
	@echo "PersistentVolumes:"
	@kubectl get pv,pvc
