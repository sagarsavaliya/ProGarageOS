# Pro Garage — Platform Admin

Super-admin UI for managing garages, subscription plans, and storage files.

## Run locally

```bash
cd Apps/web-admin
npm install
npm run dev
```

Open http://localhost:5174

Default login (after seeding): `admin@progarage.cloud` / PIN `999999`

Set API URL in `.env`:

```
VITE_API_BASE_URL=https://api.progarage.cloud/api
```

## Capabilities

- List / create / delete garages
- Reset garage operational data + onboarding
- Manage subscription plans
- Browse and delete storage files (public / local / s3 disks)
