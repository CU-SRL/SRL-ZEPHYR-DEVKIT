#!/usr/bin/env bash
# Runs on every container start before handing off to the requested command
# (bash by default). It (re)builds the repo registry by scanning /workspaces
# for repos that carry an srl.yml, prints a one-line-per-repo summary, then
# execs the command.
#
# It does NOT auto-run `west update` for every repo (that could be slow and
# unwanted with many repos). Instead `srl build <repo>` lazily runs it for the
# one repo you're building if that repo's zephyr/ is still empty.
set -euo pipefail

WORKSPACES=/workspaces

if [ ! -d "${WORKSPACES}" ] || [ -z "$(ls -A "${WORKSPACES}" 2>/dev/null)" ]; then
  cat >&2 <<EOF
warning: ${WORKSPACES} is empty -- no repos are mounted.
Launch via the host tool so repos get discovered and mounted:
  srl shell
EOF
else
  # Build/refresh the registry cache and print the summary. Never fatal.
  srl refresh || echo "warning: registry scan failed; run 'srl refresh' by hand." >&2
fi

exec "$@"
