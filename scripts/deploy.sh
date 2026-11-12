#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:?Set AWS_REGION}"
: "${EKS_CLUSTER:?Set EKS_CLUSTER}"
: "${ECR_IMAGE_URI:?Set ECR_IMAGE_URI}"
: "${NAMESPACE:?Set NAMESPACE, e.g. dev or prod}"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
sed "s|STORE_IMAGE_PLACEHOLDER|${ECR_IMAGE_URI}|g" deploy/base/deployment.yaml | kubectl apply -n "$NAMESPACE" -f -
kubectl apply -n "$NAMESPACE" -f deploy/base/service.yaml
kubectl set env deployment/store-api "APP_ENV=${NAMESPACE}" -n "$NAMESPACE"
kubectl rollout status deployment/store-api -n "$NAMESPACE" --timeout=300s
