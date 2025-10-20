# GitHub Actions CI/CD Pipeline

## 🎯 Overview

Este proyecto usa **CI/CD completo** con:
- **GitHub Actions** = CI (Build & Test)
- **ArgoCD** = CD (Deploy to Kubernetes)

---

## 🏗️ Pipeline Architecture

```
Developer Push
      ↓
┌─────────────────────────────────────────────────────────┐
│         GITHUB ACTIONS (CI)                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Checkout código                                     │
│  2. Run tests (pytest)                                  │
│  3. Build Docker image                                  │
│  4. Push to DockerHub (opcional)                        │
│  5. Update K8s manifest (deployment.yaml)               │
│  6. Commit + Push manifest                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
      ↓
    Git Push (manifest updated)
      ↓
┌─────────────────────────────────────────────────────────┐
│         ARGOCD (CD)                                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Detecta cambio en Git                              │
│  2. Compara Git vs K8s                                  │
│  3. kubectl apply deployment                            │
│  4. Rolling update                                      │
│  5. Health checks                                       │
│  6. App desplegada ✅                                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Workflows Disponibles

### 1. Backend CI/CD
**Archivo:** `.github/workflows/ci-backend.yml`

**Trigger:**
```yaml
on:
  push:
    paths:
      - 'apps/backend/**'
```

**Jobs:**
- `test` - Run pytest, linting
- `build` - Build Docker image
- `update-manifest` - Update deployment.yaml
- `notify` - Summary de resultados

**Output:**
- Docker image: `invasions-backend:<sha>`
- Manifest actualizado: `kubernetes/deployments/backend-deployment.yaml`

---

### 2. Worker CI/CD
**Archivo:** `.github/workflows/ci-worker.yml`

**Trigger:**
```yaml
on:
  push:
    paths:
      - 'apps/worker/**'
```

**Output:**
- Docker image: `invasions-worker:<sha>`
- Manifest: `kubernetes/deployments/worker-deployment.yaml`

---

### 3. Frontend CI/CD
**Archivo:** `.github/workflows/ci-frontend.yml`

**Trigger:**
```yaml
on:
  push:
    paths:
      - 'apps/frontend/**'
```

**Output:**
- Docker image: `invasions-frontend:<sha>`
- Manifest: `kubernetes/deployments/frontend-deployment.yaml`

---

## 🔐 Secrets Necesarios

Para usar DockerHub, configura estos secrets en GitHub:

```bash
Settings → Secrets and variables → Actions → New repository secret
```

**Secrets:**
- `DOCKER_USERNAME` - Tu usuario de DockerHub
- `DOCKER_PASSWORD` - Tu password/token de DockerHub

---

## 🚀 Cómo Funciona

### Ejemplo: Cambio en Backend

```bash
# 1. Developer hace cambio
vim apps/backend/main.py
git add .
git commit -m "Add new endpoint"
git push origin main
```

**GitHub Actions ejecuta:**
```
✅ Tests passed
✅ Docker image built: invasions-backend:abc123
✅ Manifest updated:
   image: invasions-backend:v2 → invasions-backend:abc123
✅ Changes pushed to Git
```

**ArgoCD detecta:**
```
🔍 Git changed detected
📊 Comparing Git vs K8s
🔄 Status: OutOfSync
🚀 Syncing...
✅ Backend deployed with image abc123
```

---

## 🔄 Flujo Completo

```
┌──────────────────────────────────────────────────────────────┐
│  1. git push apps/backend/main.py                            │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  2. GitHub Actions Workflow Triggers                         │
│     - ci-backend.yml starts                                  │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  3. Test Job                                                 │
│     pytest tests/ ✅                                         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  4. Build Job                                                │
│     docker build backend:abc123 ✅                           │
│     docker push (opcional) ✅                                │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  5. Update Manifest Job                                      │
│     sed 's/v2/abc123/' deployment.yaml ✅                    │
│     git commit + push ✅                                     │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  6. ArgoCD Detects Change                                    │
│     Poll interval: 3 minutes (or webhook)                    │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  7. ArgoCD Sync                                              │
│     kubectl apply -f deployment.yaml                         │
│     Rolling update: v2 → abc123                              │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  8. Deployment Complete                                      │
│     ✅ New pods running                                      │
│     ✅ Health checks passing                                 │
│     ✅ Service routing traffic                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔍 Monitoreo

### GitHub Actions
```
https://github.com/TU-USUARIO/k8s/actions
```

Ver:
- Workflow runs
- Logs de cada job
- Build status
- Artifacts

### ArgoCD UI
```
https://localhost:8080
```

Ver:
- Application status
- Sync status
- Health status
- Resource tree

---

## 🛠️ Setup Inicial

### 1. Sube código a GitHub

```bash
cd /Users/couriersix/Desktop/k8s

git remote add origin https://github.com/TU-USUARIO/k8s-manifests.git
git branch -M main
git push -u origin main
```

### 2. Configura DockerHub secrets (opcional)

```bash
# En GitHub:
# Settings → Secrets → New secret

DOCKER_USERNAME: tu-usuario
DOCKER_PASSWORD: tu-token
```

### 3. Habilita workflows

```bash
# Los workflows se activan automáticamente al hacer push
```

### 4. Configura ArgoCD

```bash
# Application ya creada, solo asegúrate que apunte a tu repo
kubectl edit application invasions-backend -n argocd

# Actualiza:
spec:
  source:
    repoURL: https://github.com/TU-USUARIO/k8s-manifests.git
```

---

## 🎮 Testing

### Manual trigger de workflow

```bash
# En GitHub UI:
Actions → Select workflow → Run workflow
```

### Ver logs en tiempo real

```bash
# GitHub Actions logs en UI

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

---

## 🔥 Rollback

### Opción 1: Git revert
```bash
git log --oneline
git revert <commit-hash>
git push

# ArgoCD auto-deploya versión anterior
```

### Opción 2: ArgoCD UI
```
Application → History → Select previous version → Rollback
```

### Opción 3: kubectl (emergency)
```bash
kubectl rollout undo deployment/backend-deployment
```

---

## 📊 Métricas

### CI Metrics (GitHub Actions)
- Build time: ~3-5 minutos
- Success rate: objetivo 95%+
- Test coverage: visible en logs

### CD Metrics (ArgoCD)
- Sync time: ~30-60 segundos
- Sync frequency: cada 3 minutos (polling)
- Deployment success: visible en UI

---

## 🐛 Troubleshooting

### Workflow no se ejecuta

```bash
# Verifica path filters
git log --name-only

# Debe cambiar archivos en apps/backend/** 
# para trigger ci-backend.yml
```

### Build falla

```bash
# Ver logs en GitHub Actions UI
# Common issues:
# - Tests failing
# - Docker build errors
# - Missing dependencies
```

### ArgoCD no syncea

```bash
# Check Application status
kubectl get application invasions-backend -n argocd

# Check sync policy
kubectl describe application invasions-backend -n argocd

# Force sync
kubectl patch application invasions-backend -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

---

## 🎯 Best Practices

### 1. Protect main branch
```
GitHub Settings → Branches → Add rule
- Require pull request reviews
- Require status checks to pass
```

### 2. Use semantic versioning
```yaml
# En lugar de SHA, usa tags
image: backend:v1.2.3
```

### 3. Enable webhooks (production)
```yaml
# ArgoCD Application
spec:
  source:
    repoURL: https://github.com/...
  # Webhook para sync inmediato en lugar de polling
```

### 4. Separate environments
```
overlays/
├── dev/
├── staging/
└── production/
```

---

## 📚 Referencias

- GitHub Actions Docs: https://docs.github.com/en/actions
- ArgoCD Docs: https://argo-cd.readthedocs.io/
- Docker Build Action: https://github.com/docker/build-push-action

