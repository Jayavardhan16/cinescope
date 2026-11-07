#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Missing .env file. Copy .env.example to .env and add your TMDB token."
  exit 1
fi

set -a
source .env
set +a

if [[ -z "${TMDB_ACCESS_TOKEN:-}" ]]; then
  echo "TMDB_ACCESS_TOKEN is missing in .env"
  exit 1
fi

flutter run -d web-server --web-hostname 0.0.0.0 \
  --dart-define="TMDB_ACCESS_TOKEN=${TMDB_ACCESS_TOKEN}"
