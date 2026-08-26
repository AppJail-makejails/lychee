#!/usr/bin/env bash
# shellcheck disable=SC3040
set -euo pipefail

# Check for /conf/.env file - this indicates misconfiguration
if [ -f "/conf/.env" ]; then
  echo "❌ ERROR: /conf/.env file detected"
  echo "   Containers should not have mounted .env files at /conf/.env"
  echo "   Please check your appjail-director.yml configuration"
  echo "   See https://lycheeorg.dev/docs/administration/upgrade/"
  exit 1
fi
