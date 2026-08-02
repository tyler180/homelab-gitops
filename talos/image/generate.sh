#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCHEMATIC_FILE="${SCRIPT_DIR}/schematic.yaml"

if [[ -f "${SCRIPT_DIR}/version.env" ]]; then

  # shellcheck disable=SC1091

  source "${SCRIPT_DIR}/version.env"

fi

TALOS_VERSION="${TALOS_VERSION:-v1.13.5}"
IMAGE_FACTORY="${IMAGE_FACTORY:-https://factory.talos.dev}"

if [[ ! -f "${SCHEMATIC_FILE}" ]]; then
  echo "Schematic not found: ${SCHEMATIC_FILE}" >&2
  exit 1
fi

response="$(
  curl \
    --fail \
    --silent \
    --show-error \
    --request POST \
    --data-binary "@${SCHEMATIC_FILE}" \
    "${IMAGE_FACTORY}/schematics"
)"

schematic_id="$(
  printf '%s' "${response}" |
    python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])'
)"

installer_image="factory.talos.dev/metal-installer/${schematic_id}:${TALOS_VERSION}"

cat <<EOF
Schematic ID:
${schematic_id}

Talos installer image:
${installer_image}

Upgrade example:
talosctl upgrade \\
  --nodes 192.168.1.231 \\
  --image ${installer_image}
EOF