# Pro Garage OS — Device testing setup

## Production (live server) — current testing mode

Use this when testing against **https://api.progarage.cloud/api** (no local Docker required).

### Flutter `.env` (`Apps/flutter/.env`)

```
API_BASE_URL=https://api.progarage.cloud/api
APP_ENV=production
```

### Build release APK (Windows)

```powershell
cd Apps/flutter
flutter pub get
flutter build apk --release
```

**Output:** `Apps/flutter/build/app/outputs/flutter-apk/app-release.apk`

### Install on Android phone

1. Copy APK to phone (USB, Drive, WhatsApp, etc.)
2. **Settings → Security → Install unknown apps** → allow your file manager
3. Open APK and install (uninstall old build first if install fails)
4. Phone needs internet (Wi‑Fi or mobile data) — **not** same LAN as PC

### Test credentials (demo tenant)

| Field | Value |
|-------|-------|
| Phone | `8141302341` |
| PIN | `123456` |
| Role | Owner (Patel Auto Works) |

### Android emulator (live production API)

No LAN setup needed — emulator uses internet like a real phone.

1. Keep `Apps/flutter/.env`:
   - `API_BASE_URL=https://api.progarage.cloud/api`
   - `APP_ENV=production`

2. Start emulator (first time: AVD `ProGarage_Pixel` was created):
   ```powershell
   cd Apps/flutter
   flutter emulators --launch ProGarage_Pixel
   ```

3. Run app:
   ```powershell
   flutter run -d emulator-5554
   ```

4. Test login: `8141302341` / `123456`

---

- Normal staff login
- **Forgot PIN?** on login → WhatsApp OTP → set new 6-digit PIN
- **Settings → Integrations** (owner) → Test WhatsApp connection
- Add staff without PIN → login → WhatsApp verify → set PIN

---

## Local dev (Docker on Windows)

Use when developing against your PC’s API.

### API

1. In `Apps/api/.env` set:
   - `APP_URL=http://<YOUR-PC-LAN-IP>:8000` (required for inspection photo URLs)
   - `APP_DEBUG=false` for faster responses during testing

2. Start stack: `docker compose up -d` from `Apps/api`

3. Verify: `curl http://<LAN-IP>:8000/api/health` → `version`, `api: progarageos`

### Flutter staff app

1. In `Apps/flutter/.env`:
   - `API_BASE_URL=http://<YOUR-PC-LAN-IP>:8000/api`
   - `APP_ENV=local`

2. Phone and PC must be on the **same Wi‑Fi**

3. Windows Firewall: allow inbound TCP **8000** for private networks

4. Rebuild after `.env` change: `flutter run` on device or `flutter build apk --release`

### Settings screen

Open **Dashboard → gear icon** to confirm API URL, media base URL, and health check.

## No offline demo login

Staff login requires a reachable API. Use seeded credentials from your database seeders.
