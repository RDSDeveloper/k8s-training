#!/bin/bash

# Script to test ConfigMaps and Secrets

set -e

echo "🔧 ConfigMaps & Secrets Testing"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Create ConfigMap and Secret
echo -e "${BLUE}1. Creating ConfigMap and Secret...${NC}"
kubectl apply -f kubernetes/configmaps/backend-config.yaml
kubectl apply -f kubernetes/secrets/backend-secrets.yaml
echo -e "${GREEN}✓ Created${NC}"
echo ""

# Wait a moment
sleep 2

# 2. Verify they exist
echo -e "${BLUE}2. Verifying ConfigMap and Secret...${NC}"
echo "ConfigMap:"
kubectl get configmap backend-config
echo ""
echo "Secret:"
kubectl get secret backend-secrets
echo ""

# 3. Show ConfigMap content (safe to display)
echo -e "${BLUE}3. ConfigMap content (non-sensitive):${NC}"
kubectl get configmap backend-config -o yaml | grep -A 20 "^data:"
echo ""

# 4. Show Secret keys (but not values)
echo -e "${BLUE}4. Secret keys (values hidden):${NC}"
kubectl get secret backend-secrets -o jsonpath='{.data}' | jq 'keys'
echo ""

# 5. Build and push new backend image
echo -e "${BLUE}5. Building new backend image with updated code...${NC}"
docker build -t localhost:5000/backend-api:v2 apps/backend/
docker push localhost:5000/backend-api:v2
echo -e "${GREEN}✓ Image built and pushed${NC}"
echo ""

# 6. Update deployment to use v2
echo -e "${BLUE}6. Updating deployment to use new image...${NC}"
kubectl set image deployment/backend-deployment backend=localhost:5000/backend-api:v2
echo -e "${GREEN}✓ Deployment updated${NC}"
echo ""

# 7. Wait for rollout
echo -e "${BLUE}7. Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/backend-deployment
echo -e "${GREEN}✓ Rollout complete${NC}"
echo ""

# 8. Get pod name
POD_NAME=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo -e "${BLUE}8. Testing with pod: ${POD_NAME}${NC}"
echo ""

# 9. Test environment variables
echo -e "${BLUE}9. Testing environment variables in pod...${NC}"
echo "ConfigMap env vars:"
kubectl exec $POD_NAME -- env | grep -E "APP_NAME|ENVIRONMENT|LOG_LEVEL|DB_HOST"
echo ""
echo "Secret env vars (checking existence only):"
kubectl exec $POD_NAME -- sh -c 'echo "DATABASE_PASSWORD is set: $([ ! -z \"$DATABASE_PASSWORD\" ] && echo YES || echo NO)"'
kubectl exec $POD_NAME -- sh -c 'echo "API_SECRET_KEY is set: $([ ! -z \"$API_SECRET_KEY\" ] && echo YES || echo NO)"'
echo ""

# 10. Test mounted files
echo -e "${BLUE}10. Testing mounted files in pod...${NC}"
echo "ConfigMap files:"
kubectl exec $POD_NAME -- ls -lh /etc/config/
kubectl exec $POD_NAME -- cat /etc/config/app_settings.json
echo ""
echo "Secret files:"
kubectl exec $POD_NAME -- ls -lh /etc/secrets/
kubectl exec $POD_NAME -- sh -c 'cat /etc/secrets/API_SECRET_KEY | head -c 5 && echo "***"'
echo ""

# 11. Test API endpoint
echo -e "${BLUE}11. Testing /api/config endpoint...${NC}"
echo "Getting Ingress URL..."
INGRESS_URL=$(minikube service ingress-nginx-controller -n ingress-nginx --url | head -1)
echo "Calling: ${INGRESS_URL}/api/config"
echo ""
curl -s "${INGRESS_URL}/api/config" | jq '.'
echo ""

# 12. Summary
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ All tests completed!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "You can now:"
echo "  • Check the API: curl ${INGRESS_URL}/api/config | jq"
echo "  • Update ConfigMap: kubectl edit configmap backend-config"
echo "  • Restart deployment: kubectl rollout restart deployment/backend-deployment"
echo "  • Watch pods: kubectl get pods -w"
echo ""

