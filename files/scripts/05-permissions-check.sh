#!/usr/bin/env bash
# shellcheck disable=SC3040
set -euo pipefail

echo "🔍 Validating permissions..."

# Ensure critical directories have correct rights
find /app \( -user "www" -o -group "www" \) -exec chown "noroot":"noroot" {} +
chown -R noroot:noroot /app/storage/bootstrap /app/storage/debugbar /app/storage/framework
chown -R noroot:noroot /app/bootstrap/cache
chown noroot:noroot /app/storage
chown noroot:noroot /app/public

# echo "who am i"
# id
chown -R noroot:noroot /data /config
# chmod -R 775 /data /config

echo "⏰ Set Permissions for Lychee folders..."
# Ensure noroot owns necessary directories
find /app/storage -type d \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} +
find /app/bootstrap/cache -type d \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} +

# Set restrictive permissions: 750 for directories (owner+group only, no world access)
find /app/storage -type d \( ! -perm 750 \) -exec chmod 750 {} + 2>/dev/null || true
find /app/bootstrap/cache -type d \( ! -perm 750 \) -exec chmod 750 {} + 2>/dev/null || true

# Files: 640 for sensitive, 644 for public
find /app/storage -type f \( ! -perm 640 \) -exec chmod 640 {} + 2>/dev/null || true
find /app/bootstrap/cache -type f \( ! -perm 640 \) -exec chmod 640 {} + 2>/dev/null || true

echo "⏰ Set Permissions for dist folder..."
# dist ships baked-in files (e.g. user.css, custom.js) that must always be
# writable by noroot, regardless of SKIP_PERMISSIONS_CHECKS
find /app/public/dist -type d \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} + 2>/dev/null || true
find /app/public/dist -type f \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} + 2>/dev/null || true
find /app/public/dist -type d \( ! -perm 755 \) -exec chmod 755 {} + 2>/dev/null || true
find /app/public/dist -type f \( ! -perm 644 \) -exec chmod 644 {} + 2>/dev/null || true

# Safely check SKIP_PERMISSIONS_CHECKS
skip_check="${SKIP_PERMISSIONS_CHECKS:-no}"

if [ "$skip_check" = "yes" ] || [ "$skip_check" = "YES" ]; then
  echo "⚠️ WARNING: Skipping upload permissions check"
else
  echo "⏰ Set Permissions for Upload folder (this may take a while)..."

  # More restrictive permissions - no world-readable for sensitive directories
  # Only set permissions on writable directories that need it

  # Ensure noroot owns necessary directories and files
  find /app/public/uploads -type d \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} + 2>/dev/null || true
  find /app/public/uploads -type f \( ! -user "noroot" -o ! -group "noroot" \) -exec chown "noroot":"noroot" {} + 2>/dev/null || true

  # Upload directories need 755 for web serving
  find /app/public/uploads -type d \( ! -perm 755 \) -exec chmod 755 {} + 2>/dev/null || true

  # Files: 640 for sensitive, 644 for public
  find /app/public/uploads -type f \( ! -perm 644 \) -exec chmod 644 {} + 2>/dev/null || true

fi

echo "✅ Permissions set securely"
