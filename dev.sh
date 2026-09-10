#!/usr/bin/env bash
# Convenience wrapper: `./dev.sh` opens a shell in the devkit container.
# Equivalent to `bin/srl shell`. Any args are forwarded to `bin/srl`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/bin/srl" "${@:-shell}"
