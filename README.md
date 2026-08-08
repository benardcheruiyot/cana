# GreenStone Clone (React + Node)

This workspace contains a minimal clone of the GreenStone storefront split into two folders:

- `backend` — Express API serving product data
- `frontend` — React (Vite) single-page app

Quick start:

```bash
npm install
npm run dev
```

This runs both:
- backend on http://localhost:4000
- frontend on http://localhost:5173 (opens automatically in the browser)

Production build:

```bash
npm install
npm run build
npm start
```

The `npm start` command runs the Express backend and serves the built React app from `frontend/dist`.

## Deploy Website (Recommended: Render)

This project is ready to deploy as one web service (Express serves both API and built frontend).

1. Push this repository to GitHub.
2. Create a Render account and choose New + Blueprint.
3. Select your repository. Render will detect `render.yaml`.
4. Add the required environment variables in Render:
	- `CORS_ORIGIN` = your deployed URL (e.g., https://your-app.onrender.com)
	- `APP_DOMAIN` = your custom domain (when ready)
	- `SMTP_USER` and `SMTP_PASS` from your email provider
	- `SMTP_FROM` (example: `Green Rise <no-reply@yourdomain.com>`)
	- `SMTP_REPLY_TO` (example: `info@yourdomain.com`)
5. Deploy.

After deploy, set your custom domain in Render and point DNS records at Render.

## Deploy Split Stack (Namecheap + InterServer)

This is the right setup if frontend and backend are hosted separately.

Architecture:
- Frontend static site on Namecheap shared hosting.
- Backend Node API on InterServer.

1. Deploy backend on InterServer:
- Upload project to your server.
- Install dependencies in root and backend.
- Build frontend once from project root so backend can serve dist if needed.
- Run backend with a process manager (for example PM2) on port 4000.
- Put Nginx or Apache reverse proxy in front and enable SSL.

2. Set backend environment values:
- CORS_ORIGIN=https://your-frontend-domain.com
- EMAIL_NOTIFICATIONS_ENABLED=true (if using email)
- SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS
- APP_DOMAIN=your-frontend-domain.com
- SMTP_FROM and SMTP_REPLY_TO

3. Build frontend for Namecheap:
- In frontend hosting environment, set VITE_API_BASE_URL=https://your-api-domain.com
- Run frontend build.
- Upload frontend/dist content into Namecheap public_html.

4. DNS mapping example:
- Frontend domain (for example www.yourdomain.com) -> Namecheap hosting.
- API subdomain (for example api.yourdomain.com) -> InterServer server IP.

5. SSL:
- Enable HTTPS on both domains before go-live.
- Keep CORS_ORIGIN and VITE_API_BASE_URL on HTTPS URLs.

The frontend client now reads VITE_API_BASE_URL and calls backend cross-domain safely.

Product images are loaded from the backend via `backend/public/images`, so the app includes local pictures instead of remote placeholders.

Sync source catalog (menu + dropdown categories)

```bash
npm run sync:products
```

This command pulls products from the live source WooCommerce API for all categories used in the main menu (including dropdown items) and rewrites `backend/data/products.json`.

Automate nightly catalog sync (Windows Task Scheduler)

```bash
npm run sync:products:nightly:install
```

This installs a daily scheduled task named `GreenstoneCatalogNightlySync` at `02:15` local time.

Useful commands:

```bash
npm run sync:products:nightly           # run the nightly script immediately
npm run sync:products:nightly:uninstall # remove the scheduled task
```

Nightly run logs are written to `logs/sync-products.log`.

Linting & formatting

```bash
cd frontend
npm install
npm run format    # run Prettier
npm run lint      # run ESLint (lint rules configured in .eslintrc.cjs)
```

Use `npm run lint:fix` to apply automatic ESLint fixes.
