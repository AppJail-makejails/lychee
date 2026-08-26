#!/usr/bin/env bash
# shellcheck disable=SC3040

. /lib.subr

set -euo pipefail

echo "Validating and setting PUID/PGID"

create_user

echo "  User UID: $(id -u noroot)"
echo "  User GID: $(id -g noroot)"
