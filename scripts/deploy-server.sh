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

if [ -z "$SSH_PASSWORD" ]; then
  echo "Set SSH_PASSWORD before running this script." >&2
  exit 1
fi

SSH_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" ssh -o StrictHostKeyChecking=no"
SCP_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" scp -o StrictHostKeyChecking=no"

$SSH_CMD "$SSH_USER@$SERVER_IP" 'mkdir -p ~/cana/backend'
if [ -n "$DEPLOY_ENV_FILE" ] && [ -f "$DEPLOY_ENV_FILE" ]; then
  echo "Copying $DEPLOY_ENV_FILE to remote backend .env"
  $SCP_CMD "$DEPLOY_ENV_FILE" "$SSH_USER@$SERVER_IP:~/cana/backend/.env"
fi

echo "Deploying current local source to the remote server"
tar --exclude='./backend/.env' --exclude='./backend/node_modules' --exclude='./frontend/node_modules' --exclude='./.git' -cf - backend frontend package.json package-lock.json scripts | $SSH_CMD "$SSH_USER@$SERVER_IP" 'cd ~/cana && tar -xpf -'

$SSH_CMD "$SSH_USER@$SERVER_IP" '
  set -e
  mkdir -p ~/cana
  cd ~/cana
  npm ci
  cd frontend
  npm ci
  npm run build
  cd ../backend
  npm ci
  if [ ! -f .env ]; then
    cat > .env <<"EOF"
PORT=4000
CORS_ORIGIN=https://greenlinewellnes.shop,https://www.greenlinewellnes.shop
APP_DOMAIN=greenlinewellnes.shop
EMAIL_NOTIFICATIONS_ENABLED=false
EOF
  fi
  npm install -g pm2
  pm2 delete cana || true
  pm2 start index.js --name cana --watch false --cwd "$PWD"
  pm2 save
'

echo "Deployment completed."
