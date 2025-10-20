#!/bin/bash

# Load test script - generates artificial traffic to trigger HPA

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      HPA LOAD TEST - Stress Backend API     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Get backend pod
BACKEND_POD=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo -e "${GREEN}✓ Using pod: ${BACKEND_POD}${NC}"
echo ""

echo -e "${YELLOW}📊 Initial state:${NC}"
kubectl get hpa backend-hpa 2>/dev/null || echo "HPA not yet active"
kubectl get pods -l app=backend
echo ""

echo -e "${RED}🔥 Starting load test...${NC}"
echo -e "${YELLOW}This will generate CPU load to trigger autoscaling${NC}"
echo ""

# Create a load generator pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
spec:
  containers:
  - name: load-generator
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - |
      echo "Starting infinite load generation..."
      while true; do
        wget -q -O- http://backend-service:8000/api/cities > /dev/null 2>&1
        wget -q -O- http://backend-service:8000/api/tribes > /dev/null 2>&1
        wget -q -O- http://backend-service:8000/api/cities/1/invasions > /dev/null 2>&1
      done
  restartPolicy: Never
EOF

echo ""
echo -e "${GREEN}✓ Load generator created${NC}"
echo ""

echo -e "${BLUE}📈 Watching HPA (this will update every 15 seconds)${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop watching${NC}"
echo ""
echo "Current replicas → Target CPU → Current CPU"
echo "─────────────────────────────────────────────"

# Watch HPA for 5 minutes or until interrupted
kubectl get hpa backend-hpa --watch

