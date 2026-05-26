#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: package-chart.sh [--chart-dir charts/kubecert] [--destination dist] [--repo-url <url>] [--skip-index]

Builds dependency archives, lints, packages, validates, and indexes the Kubecert Helm chart.

Examples:
  scripts/release/package-chart.sh
  scripts/release/package-chart.sh --destination public --repo-url https://Hoony-Song.github.io/kubecert-chart
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CHART_DIR="charts/kubecert"
DESTINATION="dist"
REPO_URL=""
SKIP_INDEX=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chart-dir)
      CHART_DIR="${2:-}"
      shift 2
      ;;
    --destination)
      DESTINATION="${2:-}"
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --skip-index)
      SKIP_INDEX=true
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

if [[ -z "${CHART_DIR}" || -z "${DESTINATION}" ]]; then
  usage >&2
  exit 2
fi

if [[ "${CHART_DIR}" != /* ]]; then
  CHART_DIR="${REPO_ROOT}/${CHART_DIR}"
fi
if [[ "${DESTINATION}" != /* ]]; then
  DESTINATION="${REPO_ROOT}/${DESTINATION}"
fi

mkdir -p "${DESTINATION}"

helm repo add bitnami https://charts.bitnami.com/bitnami --force-update >/dev/null
helm repo add kedacore https://kedacore.github.io/charts --force-update >/dev/null
helm repo update >/dev/null

helm dependency build "${CHART_DIR}"
helm lint "${CHART_DIR}"

PACKAGE_OUTPUT="$(helm package "${CHART_DIR}" --destination "${DESTINATION}")"
echo "${PACKAGE_OUTPUT}"

PACKAGE_PATH="$(printf '%s\n' "${PACKAGE_OUTPUT}" | sed -n 's/^Successfully packaged chart and saved it to: //p')"
if [[ -z "${PACKAGE_PATH}" ]]; then
  PACKAGE_PATH="$(find "${DESTINATION}" -maxdepth 1 -type f -name 'kubecert-*.tgz' -print | sort | tail -n 1)"
fi
if [[ -z "${PACKAGE_PATH}" || ! -f "${PACKAGE_PATH}" ]]; then
  echo "failed to locate packaged chart in ${DESTINATION}" >&2
  exit 1
fi

"${SCRIPT_DIR}/validate-chart-package.sh" "${PACKAGE_PATH}"

if [[ "${SKIP_INDEX}" != true ]]; then
  index_args=("${DESTINATION}")
  if [[ -n "${REPO_URL}" ]]; then
    index_args+=(--url "${REPO_URL}")
  fi
  helm repo index "${index_args[@]}"
  echo "index: ${DESTINATION}/index.yaml"
fi

echo "package: ${PACKAGE_PATH}"
