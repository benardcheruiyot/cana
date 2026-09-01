# Deployment setup

Add these GitHub repository secrets:

- INTERSERVER_HOST: your server IP or hostname
- INTERSERVER_USER: SSH username
- INTERSERVER_PRIVATE_KEY: private SSH key for the server (recommended; use key-based auth instead of a password)

Optional values:
- APP_DOMAIN: defaults to natuleaf.site
- CORS_ORIGIN: defaults to https://natuleaf.site,https://www.natuleaf.site
- REMOTE_APP_DIR: defaults to /opt/natuleaf-storefront

The workflow will:
1. install dependencies
2. build the frontend
3. deploy the repository to your InterServer host using SSH key auth
4. restart the app with PM2

Generate a key pair locally with:

```bash
ssh-keygen -t ed25519 -C "git-actions@natuleaf" -f ~/.ssh/natuleaf_interserver
```

Then add the public key to your server's ~/.ssh/authorized_keys and paste the private key contents into the GitHub secret.

If your hosting uses a different app directory or startup command, adjust the deploy script in .github/workflows/ci-cd.yml.
