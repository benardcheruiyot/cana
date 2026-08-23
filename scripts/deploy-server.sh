#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if command -v sshpass >/dev/null 2>&1; then
  SSHPASS_CMD="sshpass"
elif [ -n "${SSHPASS_BINARY:-}" ] && [ -x "${SSHPASS_BINARY}" ]; then
  SSHPASS_CMD="$SSHPASS_BINARY"
elif [ -x "/mnt/c/Users/bcher/AppData/Local/Temp/sshpass.exe" ]; then
  SSHPASS_CMD="/mnt/c/Users/bcher/AppData/Local/Temp/sshpass.exe"
else
  echo "sshpass not found. Set SSHPASS_BINARY to its path or install sshpass." >&2
  exit 1
fi

if [ ! -d .git ]; then
  echo "This script must be run from the repository root." >&2
  exit 1
fi

if [ -z "${1:-}" ]; then
  echo "Usage: ./scripts/deploy-server.sh <server-ip>" >&2
  exit 1
fi

SERVER_IP="$1"
SSH_USER="${SSH_USER:-root}"
SSH_PASSWORD="${SSH_PASSWORD:-}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-backend/.env}"
REMOTE_APP_DIR="${REMOTE_APP_DIR:-/opt/greenstone-storefront}"
APP_NAME="greenstone-storefront"
APP_PORT="${APP_PORT:-4100}"

case "$REMOTE_APP_DIR" in
  /|/opt|/var/www|/var/www/html|/home|*/cana|*/html)
    echo "REMOTE_APP_DIR must be a dedicated directory for this app (for example /opt/greenstone-storefront)." >&2
    exit 1
    ;;
esac

if [ -z "$SSH_PASSWORD" ]; then
  echo "Set SSH_PASSWORD before running this script." >&2
  exit 1
fi

SSH_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" ssh -o StrictHostKeyChecking=no"
SCP_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" scp -o StrictHostKeyChecking=no"

$SSH_CMD "$SSH_USER@$SERVER_IP" "mkdir -p '$REMOTE_APP_DIR/backend'"
if [ -n "$DEPLOY_ENV_FILE" ] && [ -f "$DEPLOY_ENV_FILE" ]; then
  echo "Copying $DEPLOY_ENV_FILE to remote backend .env"
  $SCP_CMD "$DEPLOY_ENV_FILE" "$SSH_USER@$SERVER_IP:$REMOTE_APP_DIR/backend/.env"
fi

echo "Deploying current local source to the remote server"
tar --exclude='./backend/.env' --exclude='./backend/node_modules' --exclude='./frontend/node_modules' --exclude='./.git' -cf - backend frontend package.json package-lock.json scripts cana-optimized.conf | $SSH_CMD "$SSH_USER@$SERVER_IP" "cd '$REMOTE_APP_DIR' && tar -xpf -"

$SSH_CMD "$SSH_USER@$SERVER_IP" "
  set -e
  mkdir -p '$REMOTE_APP_DIR'
  cd '$REMOTE_APP_DIR'
  npm ci
  cd frontend
  npm ci
  npm run build
  cd ../backend
  npm ci
  if [ ! -f .env ]; then
    printf '%s\\n' 'PORT=$APP_PORT' 'CORS_ORIGIN=https://greenlinewellnes.shop,https://www.greenlinewellnes.shop' 'APP_DOMAIN=greenlinewellnes.shop' 'EMAIL_NOTIFICATIONS_ENABLED=false' > .env
  fi
  npm install -g pm2
  pm2 startOrRestart ecosystem.config.js --only '$APP_NAME' --update-env
  pm2 save
  if command -v nginx >/dev/null 2>&1; then
    install -m 0644 cana-optimized.conf /etc/nginx/sites-available/greenstone-storefront.conf
    mkdir -p /etc/nginx/sites-enabled
    for enabled_site in /etc/nginx/sites-enabled/*; do
      if [ -f "\$enabled_site" ] && grep -qE 'server_name[[:space:]]+[^;]*greenlinewellnes\.shop' "\$enabled_site" && [ "\$enabled_site" != /etc/nginx/sites-enabled/greenstone-storefront.conf ]; then
        rm -f "\$enabled_site"
      fi
    done
    ln -sfn /etc/nginx/sites-available/greenstone-storefront.conf /etc/nginx/sites-enabled/greenstone-storefront.conf
    nginx -t
    systemctl reload nginx
  fi
"

echo "Deployment completed."
