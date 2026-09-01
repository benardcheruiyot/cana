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
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-backend/.env}"
REMOTE_APP_DIR="${REMOTE_APP_DIR:-/opt/natuleaf-storefront}"
APP_NAME="natuleaf-storefront"
APP_PORT="${APP_PORT:-4101}"
APP_DOMAIN="${APP_DOMAIN:-natuleaf.site}"
CORS_ORIGIN="${CORS_ORIGIN:-https://natuleaf.site,https://www.natuleaf.site}"

case "$REMOTE_APP_DIR" in
  /|/opt|/var/www|/var/www/html|/home|*/cana|*/html)
    echo "REMOTE_APP_DIR must be a dedicated directory for this app (for example /opt/natuleaf-storefront)." >&2
    exit 1
    ;;
esac

if [ -n "$SSH_PRIVATE_KEY" ]; then
  SSH_KEY_FILE="$HOME/.ssh/gh_deploy_key"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  
  # Handle both literal \n and actual newlines in the key
  echo "$SSH_PRIVATE_KEY" | sed 's/\\n/\n/g' > "$SSH_KEY_FILE"
  
  if [ ! -f "$SSH_KEY_FILE" ] || [ ! -s "$SSH_KEY_FILE" ]; then
    echo "Error: Failed to create SSH key file at $SSH_KEY_FILE" >&2
    ls -la "$SSH_KEY_FILE" 2>&1 || echo "File does not exist"
    exit 1
  fi
  
  chmod 600 "$SSH_KEY_FILE"
  
  if [ ! -r "$SSH_KEY_FILE" ]; then
    echo "Error: SSH key file is not readable." >&2
    exit 1
  fi
  
  echo "SSH key file created at $SSH_KEY_FILE ($(wc -c < "$SSH_KEY_FILE") bytes)"
  
  # Cleanup on exit
  trap "rm -f \"$SSH_KEY_FILE\"" EXIT
  
  SSH_CMD="ssh -i \"$SSH_KEY_FILE\" -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ConnectTimeout=10 -v"
  SCP_CMD="scp -i \"$SSH_KEY_FILE\" -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ConnectTimeout=10"
elif [ -n "$SSH_PASSWORD" ]; then
  if command -v sshpass >/dev/null 2>&1; then
    SSHPASS_CMD="sshpass"
  elif [ -n "${SSHPASS_BINARY:-}" ] && [ -x "${SSHPASS_BINARY}" ]; then
    SSHPASS_CMD="$SSHPASS_BINARY"
  elif [ -x "/mnt/c/Users/bcher/AppData/Local/Temp/sshpass.exe" ]; then
    SSHPASS_CMD="/mnt/c/Users/bcher/AppData/Local/Temp/sshpass.exe"
  else
    echo "sshpass not found. Set SSH_PRIVATE_KEY for key-based auth, or install sshpass for password auth." >&2
    exit 1
  fi
  SSH_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" ssh -o StrictHostKeyChecking=no"
  SCP_CMD="$SSHPASS_CMD -p \"$SSH_PASSWORD\" scp -o StrictHostKeyChecking=no"
else
  echo "Set SSH_PRIVATE_KEY or SSH_PASSWORD before running this script." >&2
  exit 1
fi

echo "Testing SSH connection to $SSH_USER@$SERVER_IP..."
if ! $SSH_CMD "$SSH_USER@$SERVER_IP" "echo 'SSH connection successful.'" 2>&1 | head -n 5; then
  echo "Error: Cannot connect to $SSH_USER@$SERVER_IP via SSH. Check host, credentials, and network." >&2
  exit 1
fi

$SSH_CMD "$SSH_USER@$SERVER_IP" "mkdir -p '$REMOTE_APP_DIR/backend'"
if [ -n "$DEPLOY_ENV_FILE" ] && [ -f "$DEPLOY_ENV_FILE" ]; then
  echo "Copying $DEPLOY_ENV_FILE to remote backend .env"
  $SCP_CMD "$DEPLOY_ENV_FILE" "$SSH_USER@$SERVER_IP:$REMOTE_APP_DIR/backend/.env"
fi

echo "Deploying current local source to the remote server"
tar --exclude='./backend/.env' --exclude='./backend/node_modules' --exclude='./frontend/node_modules' --exclude='./.git' -cf - backend frontend package.json package-lock.json scripts natuleaf-site.conf | $SSH_CMD "$SSH_USER@$SERVER_IP" "cd '$REMOTE_APP_DIR' && tar -xpf -"

$SSH_CMD "$SSH_USER@$SERVER_IP" "
  set -e
  cd '$REMOTE_APP_DIR'
  npm ci
  cd frontend
  npm ci
  npm run build
  cd ../backend
  npm ci
  if [ ! -f .env ]; then
    cat > .env <<ENVFILE
PORT=${APP_PORT}
CORS_ORIGIN=${CORS_ORIGIN}
APP_DOMAIN=${APP_DOMAIN}
EMAIL_NOTIFICATIONS_ENABLED=false
ENVFILE
  fi
  npm install -g pm2
  pm2 startOrRestart ecosystem.config.js --only '$APP_NAME' --update-env
  pm2 save
  if command -v nginx >/dev/null 2>&1; then
    install -m 0644 natuleaf-site.conf /etc/nginx/sites-available/natuleaf-site.conf
    mkdir -p /etc/nginx/sites-enabled

    # Only manage the natuleaf vhost. Do not delete unrelated site configs on a shared
    # InterServer box, because other apps such as yr27 may be hosted there as separate vhosts.
    if [ -f /etc/nginx/sites-enabled/default ]; then rm -f /etc/nginx/sites-enabled/default; fi
    if [ -f /etc/nginx/sites-enabled/000-default ]; then rm -f /etc/nginx/sites-enabled/000-default; fi

    ln -sfn /etc/nginx/sites-available/natuleaf-site.conf /etc/nginx/sites-enabled/natuleaf-site.conf
    nginx -t
    systemctl reload nginx
  fi
"

echo "Deployment completed."
