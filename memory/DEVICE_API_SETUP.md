# GarageFlow — Physical device API setup

## API (Docker on Windows)

1. In `Apps/api/.env` set:
   - `APP_URL=http://<YOUR-PC-LAN-IP>:8000` (required for inspection photo URLs)
   - `APP_DEBUG=false` for faster responses during testing

2. Start stack: `docker compose up -d` from `Apps/api`

3. Verify: `curl http://<LAN-IP>:8000/api/health` → `version`, `api: garageflow`

## Flutter staff app

1. In `Apps/flutter/.env`:
   - `API_BASE_URL=http://<YOUR-PC-LAN-IP>:8000/api`
   - `APP_ENV=local`

2. Phone and PC must be on the **same Wi‑Fi**

3. Windows Firewall: allow inbound TCP **8000** for private networks

4. Rebuild after `.env` change: `flutter run` on device

## Settings screen

Open **Dashboard → gear icon** to confirm API URL, media base URL, and health check.

## No offline demo login

Staff login requires a reachable API. Use seeded credentials from your database seeders.
