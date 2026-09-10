#!/usr/bin/env bash
# Every registry id must resolve to an init_* handler or a rev_start_* payload fn.
set -u
cd "$(dirname "$0")/.."

bash -c '
source scripts/shell-core.sh
source scripts/shell-registry.sh
source scripts/shell-payloads.sh
export SCRIPTS_DIR="$PWD/scripts"
source scripts/shell-init-server.sh
source scripts/shell-init-mux.sh
source scripts/shell-init-reverse.sh
source scripts/shell-init-tunnel.sh
source scripts/shell-init-bind.sh
source scripts/shell-init-web.sh
source scripts/shell-init-debug.sh
missing=0
for id in "${REGISTRY_IDS[@]}"; do
  fn="init_${id//-/_}"
  if ! declare -f "$fn" > /dev/null && ! declare -f "rev_start_${id//-/_}" > /dev/null; then
    echo "MISSING handler for: $id"
    missing=1
  fi
done
if [ "$missing" = "0" ]; then
  echo "COVERAGE_OK: ${#REGISTRY_IDS[@]} shells covered"
else
  exit 1
fi
'
