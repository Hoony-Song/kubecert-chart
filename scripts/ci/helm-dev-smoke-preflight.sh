#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: helm-dev-smoke-preflight.sh --kubeconfig <path> --values <private-dev-values.yaml> [--release <name>] [--namespace <name>] [--allow-placeholders]

Runs the non-mutating preflight checks for a dev Helm smoke:
  - helm dependency build
  - helm lint
  - placeholder scan for the private values file
  - helm upgrade --install --dry-run --debug

This script does not install resources into the cluster.
USAGE
}

RELEASE="kubecert"
NAMESPACE="kubecert"
KUBECONFIG_PATH=""
VALUES_FILE=""
ALLOW_PLACEHOLDERS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig)
      KUBECONFIG_PATH="${2:-}"
      shift 2
      ;;
    --values)
      VALUES_FILE="${2:-}"
      shift 2
      ;;
    --release)
      RELEASE="${2:-}"
      shift 2
      ;;
    --namespace)
      NAMESPACE="${2:-}"
      shift 2
      ;;
    --allow-placeholders)
      ALLOW_PLACEHOLDERS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${KUBECONFIG_PATH}" || -z "${VALUES_FILE}" ]]; then
  usage >&2
  exit 2
fi
if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "kubeconfig not found: ${KUBECONFIG_PATH}" >&2
  exit 2
fi
if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "values file not found: ${VALUES_FILE}" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHART_DIR="${REPO_ROOT}/charts/kubecert"

if [[ "${ALLOW_PLACEHOLDERS}" != true ]]; then
  if grep -E "replace-with|example\\.com|example\\.internal|registry\\..*example|0000000000000000000000000000000000000000000000000000000000000000|dev-replace|vYYYYMMDD" "${VALUES_FILE}" >/dev/null; then
    echo "private dev values still contain public placeholders; refusing dev smoke preflight" >&2
    exit 2
  fi
fi

helm dependency build "${CHART_DIR}"
helm lint "${CHART_DIR}" -f "${VALUES_FILE}"
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --kubeconfig "${KUBECONFIG_PATH}" \
  -f "${VALUES_FILE}" \
  --dry-run \
  --debug
