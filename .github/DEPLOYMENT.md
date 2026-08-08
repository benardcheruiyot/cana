# Deployment setup

Add these GitHub repository secrets:

- INTERSERVER_HOST: your server IP or hostname
- INTERSERVER_USER: SSH username
- INTERSERVER_PASSWORD: SSH password for the server

The workflow will:
1. install dependencies
2. build the frontend
3. deploy the repository to your interServer host using SSH
4. restart the app with PM2

If your hosting uses a different app directory or startup command, adjust the deploy script in .github/workflows/ci-cd.yml.
