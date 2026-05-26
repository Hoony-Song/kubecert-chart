#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: validate-chart-package.sh <chart-package.tgz>

Validates that a packaged Kubecert chart:
  - is readable by Helm
  - contains bundled dependency charts
  - does not contain known secret/private file names
  - does not contain common private placeholder or key markers
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

PACKAGE_PATH="${1:-}"
if [[ -z "${PACKAGE_PATH}" ]]; then
  usage >&2
  exit 2
fi
if [[ ! -f "${PACKAGE_PATH}" ]]; then
  fail "chart package not found: ${PACKAGE_PATH}"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

LIST_FILE="${TMP_DIR}/package-files.txt"
tar --warning=no-timestamp -tzf "${PACKAGE_PATH}" > "${LIST_FILE}"

grep -qx "kubecert/Chart.yaml" "${LIST_FILE}" || fail "missing kubecert/Chart.yaml"
grep -qx "kubecert/values.yaml" "${LIST_FILE}" || fail "missing kubecert/values.yaml"

for dependency in postgresql redis keda; do
  if ! grep -Eq "^kubecert/charts/${dependency}-[0-9][^/]*\\.tgz$|^kubecert/charts/${dependency}/Chart\\.yaml$" "${LIST_FILE}"; then
    fail "missing bundled dependency chart: ${dependency}"
  fi
done

if grep -Ei '(^|/)(id_ed25519(\.pub)?|cert-ssh(\.pub)?|kubeconfig|dev-config|\.env(\..*)?|.*\.pem|.*\.key)$' "${LIST_FILE}" >/tmp/kubecert-chart-forbidden-files.txt; then
  cat /tmp/kubecert-chart-forbidden-files.txt >&2
  fail "forbidden secret/private file name found in chart package"
fi

EXTRACT_DIR="${TMP_DIR}/extract"
mkdir -p "${EXTRACT_DIR}"
tar --warning=no-timestamp -xzf "${PACKAGE_PATH}" -C "${EXTRACT_DIR}"

mapfile -d '' FIRST_PARTY_FILES < <(find "${EXTRACT_DIR}/kubecert" \
  -path "${EXTRACT_DIR}/kubecert/charts" -prune -o \
  -type f \
  ! -name '*.tgz' \
  -print0)

if [[ "${#FIRST_PARTY_FILES[@]}" -gt 0 ]] && grep -IE \
  'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|(api|admin|www)\.sweetlabs\.kr|192\.168\.|registry\.example|example\.(com|internal)|dev-replace|vYYYYMMDD|0000000000000000000000000000000000000000000000000000000000000000' \
  "${FIRST_PARTY_FILES[@]}" >/tmp/kubecert-chart-forbidden-content.txt; then
  cat /tmp/kubecert-chart-forbidden-content.txt >&2
  fail "forbidden private marker found in first-party chart package content"
fi

helm show chart "${PACKAGE_PATH}" >/dev/null

echo "validated: ${PACKAGE_PATH}"
