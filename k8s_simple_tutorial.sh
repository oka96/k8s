#!/usr/bin/env bash
set -euo pipefail

# A simple, interactive Kubernetes tutorial.
# Run: ./k8s_simple_tutorial.sh

NAMESPACE="k8s-tutorial"
APP_NAME="hello-nginx"
IMAGE="nginx:stable"
PORT="80"

pause() {
  read -r -p "Press Enter to continue... " _
}

step() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed or not in PATH."
    exit 1
  fi
}

need_cmd kubectl

step "0) Check Kubernetes cluster connection"
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "kubectl cannot reach a Kubernetes cluster."
  echo "Start your local cluster first (examples):"
  echo "  minikube start"
  echo "  kind create cluster"
  exit 1
fi
kubectl cluster-info
pause

step "1) Create a namespace: ${NAMESPACE}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl get ns "${NAMESPACE}"
pause

step "2) Create a deployment (${APP_NAME}) using image ${IMAGE}"
kubectl -n "${NAMESPACE}" create deployment "${APP_NAME}" --image="${IMAGE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE}" get deployment "${APP_NAME}"
pause

step "3) Wait until pod is ready"
kubectl -n "${NAMESPACE}" rollout status deployment/"${APP_NAME}" --timeout=120s
kubectl -n "${NAMESPACE}" get pods -o wide
pause

step "4) Expose deployment as a ClusterIP service"
kubectl -n "${NAMESPACE}" expose deployment "${APP_NAME}" --port="${PORT}" --target-port="${PORT}" --name="${APP_NAME}" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE}" get svc "${APP_NAME}"
pause

step "5) Scale deployment to 2 replicas"
kubectl -n "${NAMESPACE}" scale deployment "${APP_NAME}" --replicas=2
kubectl -n "${NAMESPACE}" get pods -o wide
pause

step "6) Show useful inspect commands"
echo "Describe deployment:"
kubectl -n "${NAMESPACE}" describe deployment "${APP_NAME}" | sed -n '1,80p'
echo
echo "Recent pod logs:"
POD_NAME="$(kubectl -n "${NAMESPACE}" get pods -l app="${APP_NAME}" -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "${NAMESPACE}" logs "${POD_NAME}" --tail=20
pause

step "7) Optional: local access with port-forward"
echo "In a second terminal, run:"
echo "  kubectl -n ${NAMESPACE} port-forward svc/${APP_NAME} 8080:80"
echo "Then open http://localhost:8080"
pause

step "8) Cleanup resources"
kubectl delete namespace "${NAMESPACE}"
echo "Namespace ${NAMESPACE} deleted. Tutorial complete."
