# Vehicle Catalog — Master Data

Platform-wide lookup tables for car garage vehicle intake (make → model → variant → color).

## Your approved scope
- **Focus:** Car garages (India passenger cars / SUVs / MUVs)
- **Future-ready:** `vehicle_category` supports `bike`, `commercial`, `luxury` — inactive until seeded
- **Colors:** 20 standard colors, mapped to variants via `variant_colors.csv`
- **Year filtering:** Variants carry `year_from` / `year_to`; UI will filter by selected year

## Tables
| Table | Purpose |
|---|---|
| `vehicle_makes` | Brand (Maruti Suzuki, Hyundai…) |
| `vehicle_models` | Model under a make (Swift, Creta…) |
| `vehicle_variants` | Trim + fuel + transmission + year range |
| `vehicle_colors` | Standard color palette (seeded) |
| `vehicle_variant_colors` | Which colors apply to each variant |
| `vehicles.*_id` | Optional FK links on tenant vehicles (text fields kept for compatibility) |

## Deploy (one-time)
```bash
php artisan migrate
php artisan db:seed --class=VehicleColorSeeder
```

## When your dataset is ready

### Option A — JSON (CarWale scrape)
File: `Apps/api/database/seeders/data/vehicle-catalog/vehicle_master.json`

```bash
php artisan migrate
php artisan progarage:import-vehicle-catalog --json=vehicle_master.json --seed-colors --fresh
```

Import rules:
- **Car garages (active):** mainstream brands → `vehicle_category = car`, `is_active = true`
- **Stored for later:** luxury (Aston Martin, Ferrari…) and commercial (Force, Isuzu) → imported but inactive
- **Colors:** manufacturer color names mapped to 20 standard colors per variant
- **Year filter:** each variant stores `year_from` / `year_to` from scraped year
- **Skipped:** placeholder `range` variants with no fuel/transmission/colors

### Option B — CSV
1. Place CSV files in `Apps/api/database/seeders/data/vehicle-catalog/` (templates included)
2. Run:
```bash
php artisan progarage:import-vehicle-catalog --seed-colors --fresh
```
Use `--path=/path/to/your/csvs` if files are elsewhere.

## CSV formats

### makes.csv
`name, vehicle_category, country_code, sort_order, is_active`

### models.csv
`make_name, model_name, body_type, vehicle_category, sort_order, is_active`

### variants.csv
`make_name, model_name, variant_name, fuel_type, transmission, year_from, year_to, vehicle_category, sort_order, is_active`

- `fuel_type`: petrol | diesel | electric | cng | lpg | hybrid
- `transmission`: manual | automatic | cvt | amt
- `year_from` / `year_to`: used for year-based suggestions

### variant_colors.csv
`make_name, model_name, variant_name, year_from, color_name, is_default, vehicle_category`

- `color_name` must match a seeded color slug/name (e.g. `White`, `Pearl White`)
- `is_default`: 1 = primary color for that variant

## Sample data
Template folder includes 2 makes, 2 models, 3 variants — enough to verify import end-to-end before your full dataset arrives.

## Next (after import)
- Search/autocomplete API endpoints (`GET /vehicle-catalog/makes?q=mar&year=2021`)
- Wire Add/Edit Vehicle screens (Flutter + web) to pick from catalog instead of free text
