#!/bin/bash

# Stop load test and clean up

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Stopping load test...${NC}"
echo ""

# Delete load generator
kubectl delete pod load-generator --ignore-not-found=true

echo -e "${GREEN}✓ Load generator deleted${NC}"
echo ""

echo -e "${YELLOW}📊 Current state:${NC}"
kubectl get hpa backend-hpa
echo ""
kubectl get pods -l app=backend
echo ""

echo -e "${GREEN}✓ HPA will scale down in ~60 seconds${NC}"
echo "Watch it with: kubectl get hpa backend-hpa --watch"

