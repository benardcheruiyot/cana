#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

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

if [ -z "$SSH_PASSWORD" ]; then
  echo "Set SSH_PASSWORD before running this script." >&2
  exit 1
fi

sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" '
  set -e
  mkdir -p ~/cana
  cd ~/cana
  if [ ! -d .git ]; then
    git clone https://github.com/benardcheruiyot/cana.git .
  else
    git fetch origin main
    git checkout main
    git pull --ff-only origin main
  fi
  npm ci
  cd frontend
  npm ci
  npm run build
  cd ../backend
  npm ci
  cat > .env <<"EOF"
PORT=4000
CORS_ORIGIN=https://greenlinewellnes.shop,https://www.greenlinewellnes.shop
APP_DOMAIN=greenlinewellnes.shop
EOF
  npm install -g pm2
  pm2 delete cana || true
  pm2 start index.js --name cana --watch false --cwd "$PWD"
  pm2 save
'

echo "Deployment completed."
