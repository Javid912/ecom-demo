# E-Commerce Data Stack — Build Checklist v1.0
> Battle-tested. Built once, refined from real experience.  
> Use this for every new client project.

---

## Stack Overview
```
Shopify (API) → Airbyte Cloud → BigQuery → dbt Cloud → Looker Studio
```
**Monthly cost per client:** ~€0–50 (BigQuery free tier + Airbyte free tier covers most SMEs)  
**Setup time (you now):** 2–3 days  
**Setup time (client #3+):** 4–8 hours  

---

## Pre-flight: Accounts to Create Once
These are YOUR accounts — reused across all clients.

- [ ] Google Cloud account (console.cloud.google.com)
- [ ] Airbyte Cloud account (cloud.airbyte.com)
- [ ] dbt Cloud account (cloud.getdbt.com)
- [ ] GitHub account
- [ ] Looker Studio (lookerstudio.google.com) — uses Google account

---

## Phase 0 — Repo & Local Setup
**Time: ~1 hour**

- [ ] Create GitHub repo named `[client]-analytics` (e.g. `sportgear-analytics`)
- [ ] Create local folder structure:
  ```bash
  mkdir -p ~/projects/[client]-analytics/{dbt,docs}
  ```
- [ ] Add `.gitignore` — include:
  ```
  dbt/profiles.yml
  *.json
  .env
  target/
  dbt_packages/
  ```
- [ ] Initial commit and push to GitHub

**⚠️ Gotcha:** Never commit service account JSON files to GitHub.

---

## Phase 1 — GCP & BigQuery Setup
**Time: ~1 hour**

- [ ] Create new GCP project — name: `[client]-analytics`
- [ ] Enable BigQuery API, BigQuery Storage API
- [ ] Create datasets — **CRITICAL: set region to `EU` for all German clients**
  - [ ] `ecom_raw` — where Airbyte loads raw data
  - [ ] `ecom_marts` — where dbt writes production tables
- [ ] Create Service Account #1 for Airbyte:
  - Name: `airbyte-loader`
  - Roles: `BigQuery Data Editor` + `BigQuery Job User` 
  - Download JSON → save securely (NOT in repo)
- [ ] Create Service Account #2 for dbt:
  - Name: `dbt-transformer`
  - Roles: `BigQuery Data Editor` + `BigQuery Job User` + `BigQuery Read Session User`
  - Download JSON → save securely

**⚠️ Gotcha:** Always create datasets in EU region upfront.  
dbt Cloud defaults to US — if datasets are in different regions queries will fail with "dataset not found" error.

**⚠️ Gotcha:** Create project in CLIENT's GCP account for real projects, not yours.  
You are the builder, not the infrastructure owner.

---

## Phase 2 — Shopify Setup
**Time: ~30–45 minutes**

### Create Dev Store (demo only)
- [ ] Go to partners.shopify.com → Create Partner account
- [ ] Stores → Add store → Development store
- [ ] Install sample data app: search "Egnition Sample Data" in Shopify App Store
- [ ] Generate at least 100 orders with 6+ months of history

### Get API Token (dev store OR real client store)
**The correct flow — NOT via Partner Dev Dashboard:**

- [ ] Go to: `[storename].myshopify.com/admin/settings/apps`
- [ ] Scroll to bottom → click **"Develop apps for your store"**
- [ ] Click **"Allow custom app development"** → confirm (one-time)
- [ ] Create app → name: `Airbyte Connector`
- [ ] Configuration tab → Admin API scopes → enable:
  - `read_orders`
  - `read_customers`
  - `read_products`
  - `read_inventory`
- [ ] Save → Install app
- [ ] Copy **Admin API access token** — shown once only, save immediately

**⚠️ Gotcha:** The Partner Dev Dashboard creates OAuth apps, NOT Admin API token apps.  
These are different things. Airbyte needs the Admin API token. Always use store admin settings, not the Partner dashboard.

**⚠️ Gotcha:** Token shown only once after installation. Save it immediately in a password manager.  
If lost → uninstall and reinstall the app to generate a new one.

**⚠️ Note on sample data:** Egnition app sets `source_name = 1608003` (app ID) on all orders.  
Real client stores will have proper `source_name` values (web, google, instagram etc).  
For demo: use modulo logic on order_id to simulate channel distribution in dbt.

---

## Phase 3 — Airbyte Setup
**Time: ~30 minutes**

- [ ] Sign up at cloud.airbyte.com
- [ ] New Connection → Source: **Shopify**
  - Shop URL: `[storename].myshopify.com`
  - API Password: paste Admin API access token
  - Start date: 12 months ago (for real client), or earliest available
- [ ] Destination: **BigQuery**
  - Upload `airbyte-loader` service account JSON
  - Project ID: your GCP project ID
  - Dataset: `ecom_raw`
  - **Dataset location: EU** ← set this explicitly
- [ ] Select streams:
  - `orders` ✓ (contains line_items nested inside as JSON array)
  - `customers` ✓
  - `products` ✓
  - `order_refunds` ✓
  - `product_variants` ✓
  - Skip: metafields, events, smart_collections
- [ ] Sync frequency: Every 24 hours
- [ ] Run first sync → verify tables appear in BigQuery `ecom_raw`

**⚠️ Gotcha:** `order_line_items` does NOT exist as a separate stream.  
Line items are nested as a JSON array inside the `orders` table.  
Your dbt staging model uses `UNNEST(JSON_EXTRACT_ARRAY(line_items))` to flatten them.

**⚠️ Gotcha:** Airbyte creates an `airbyte_internal` dataset automatically — this is housekeeping data, do not delete it.

**⚠️ Gotcha:** Table names in BigQuery are `orders`, `customers` etc — no underscores.  
Earlier versions of Airbyte used `__orders__` naming — check your actual table names.

---

## Phase 4 — dbt Cloud Setup
**Time: ~1 hour**

### Initial Setup
- [ ] Sign up at cloud.getdbt.com
- [ ] New project → name: `[client]-analytics`
- [ ] Connect GitHub repo
- [ ] Connection: BigQuery → upload `dbt-transformer` service account JSON
- [ ] **Set Location to `EU` in Optional Settings** ← critical, easy to miss
- [ ] Create Development environment:
  - Type: Development
  - Dataset: `ecom_dev_marts`
  - Upload service account JSON
- [ ] Set personal development credentials:
  - Profile Settings → Credentials → your project
  - Dataset: `ecom_dev_marts`
  - Upload service account JSON

**⚠️ Gotcha:** dbt Cloud has TWO separate credential settings:  
1. Project connection (shared)  
2. Personal development credentials (per user)  
Both must be configured or the IDE command bar won't work.

**⚠️ Gotcha:** The Location field for BigQuery is hidden under "Optional Settings" in the connection config.  
If not set, dbt creates datasets in US even if your BigQuery data is in EU → "dataset not found" error.

**⚠️ Gotcha:** Delete the example models immediately after initializing:  
- `models/example/my_first_dbt_model.sql`  
- `models/example/my_second_dbt_model.sql`  
- `models/example/schema.yml`  
Leaving them causes build failures in production.

### dbt Project Config (`dbt_project.yml`)
```yaml
name: 'shopify_demo'
version: '1.0.0'
config-version: 2
profile: 'default'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  shopify_demo:
    staging:
      +materialized: view
    marts:
      +materialized: table
```

**⚠️ Note:** Removing `+schema` overrides puts everything in one dataset.  
Adding `+schema: staging` creates separate datasets but appends target name as prefix  
(e.g. `ecom_marts_staging`) which can be confusing. Keep it simple for solo projects.

### dbt File Structure
```
models/
├── sources.yml
├── staging/
│   ├── stg_orders.sql
│   ├── stg_order_lines.sql
│   └── stg_customers.sql
└── marts/
    ├── mart_revenue_monthly.sql
    ├── mart_marketing_performance.sql
    └── mart_customer_ltv.sql
seeds/
└── product_margins.csv
```

### sources.yml
```yaml
version: 2

sources:
  - name: ecom_raw
    database: [gcp-project-id]
    schema: ecom_raw
    tables:
      - name: orders
      - name: customers
      - name: products
      - name: order_refunds
      - name: product_variants
```

### Key dbt Patterns for Shopify Data

**Extracting from nested JSON (Shopify customer inside order):**
```sql
JSON_VALUE(customer, '$.id')          as customer_id,
JSON_VALUE(billing_address, '$.city') as billing_city,
```

**Unnesting line items (one row per product):**
```sql
from source o,
UNNEST(JSON_EXTRACT_ARRAY(o.line_items)) as line_item
```

**Always filter completed orders:**
```sql
where financial_status = 'paid'
and deleted_at is null
```

**⚠️ Gotcha:** `financial_status` values: `paid`, `pending`, `refunded`, `partially_refunded`.  
Only `paid` = real revenue. Always filter, never trust total counts from raw table.

**⚠️ Gotcha:** Shopify stores money columns as NUMERIC in BigQuery via Airbyte — no casting needed.  
JSON fields (customer, billing_address, line_items) need `JSON_VALUE()` to extract.

### Git Workflow in dbt Cloud
- dbt Cloud creates a personal branch automatically
- Work in your branch → Commit and sync → creates PR
- Merge PR to main manually (or configure auto-merge for solo projects)

### Running Models
```bash
dbt run                              # run all models
dbt run --select stg_orders          # run one model
dbt run --select staging             # run all staging models
dbt run --select marts               # run all mart models
dbt test                             # run all tests
dbt build                            # run + test together
```

---

## Phase 5 — Production Job Setup
**Time: ~15 minutes**

- [ ] Orchestration → Environments → Create new environment
  - Name: `Production`
  - Type: Deployment → **PROD**
  - dbt version: Latest
  - Dataset: `ecom_marts`
  - Upload service account JSON
- [ ] Orchestration → Jobs → Create job
  - Name: `Daily Refresh`
  - Environment: Production
  - Commands: `dbt run` then `dbt test`
  - Schedule: daily 06:00 UTC
  - Enable "Generate docs"
- [ ] Click "Run now" to test manually first
- [ ] Verify tables appear in BigQuery `ecom_marts`

**⚠️ Gotcha:** For demo/dev work — disable the schedule after testing.  
Scheduled runs count against your dbt Cloud plan limits.  
Toggle schedule off: Job → Settings → uncheck "Run on schedule".

**Dev vs Prod datasets explained:**
- `ecom_dev_marts` — your sandbox, written when you run models in the IDE manually
- `ecom_marts` — production, written when the scheduled job runs
- Looker Studio always points to `ecom_marts`
- This protects clients from seeing broken work-in-progress models

---

## Phase 6 — Looker Studio Dashboards
**Time: ~2–3 hours**

- [ ] Go to lookerstudio.google.com
- [ ] Create → Report → Add data source → BigQuery
  - Project: `[gcp-project-id]`
  - Dataset: `ecom_marts` ← production, not dev
  - Table: `mart_revenue_monthly`
- [ ] Add remaining data sources:
  - `mart_marketing_performance`
  - `mart_customer_ltv`
- [ ] Build 3 pages:

### Page 1 — Revenue & Margin
Data source: `mart_revenue_monthly`
- 4 scorecards: gross_revenue, total_orders, unique_customers, avg_order_value
- Bar chart: order_month vs gross_revenue
- Line chart: order_month vs total_orders
- Line chart: order_month vs avg_order_value

### Page 2 — Customer LTV
Data source: `mart_customer_ltv`
- 3 scorecards: total customers, repeat buyers (filter is_repeat_buyer=true), avg total_revenue
- Table: first_name, last_name, city, total_orders, total_revenue, ltv_tier, top_vendor
- Pie chart: ltv_tier distribution
- Pie chart: is_repeat_buyer

### Page 3 — Marketing Performance
Data source: `mart_marketing_performance`
- 4 scorecards: gross_revenue, total_orders, unique_customers, avg_order_value
- Bar chart: channel vs gross_revenue
- Table: channel, total_orders, gross_revenue, avg_order_value, revenue_share_pct
- Pie chart: channel vs gross_revenue

**⚠️ Note on marketing data:** With real client Shopify stores, `source_name` field contains  
actual channel data (web, google, instagram). With Egnition sample data it returns the app ID.  
For demo: use modulo logic on order_id in dbt to simulate channel distribution.

---

## Handover Checklist (for real client projects)
- [ ] All infrastructure created in CLIENT's GCP account
- [ ] Client has owner access to GCP project
- [ ] Looker Studio report shared with client (view access)
- [ ] dbt Cloud project shared with client (read access)
- [ ] Documentation generated (dbt docs)
- [ ] Handover document written explaining: what runs when, how to add new metrics, who to contact
- [ ] Monthly retainer scope agreed: monitoring, new metrics, adjustments

---

## Time Log (actual, first build)
| Phase | Estimated | Actual |
|---|---|---|
| Phase 0 — Repo setup | 1h | ~30 min |
| Phase 1 — GCP/BigQuery | 1h | ~45 min |
| Phase 2 — Shopify API token | 30 min | ~45 min (UI changed) |
| Phase 3 — Airbyte | 30 min | ~30 min |
| Phase 4 — dbt Cloud setup | 1h | ~2h (region issues, credentials) |
| Phase 4 — dbt models | 2h | ~3h (schema discovery, JSON unnesting) |
| Phase 5 — Production job | 15 min | ~30 min (example model cleanup) |
| Phase 6 — Looker Studio | 2h | ~1.5h |
| **Total** | **~8h** | **~9.5h** |

**Notes:**
- Most extra time was BigQuery EU/US region mismatch — now documented, won't happen again
- Shopify UI changed significantly — Partner Dev Dashboard vs store admin custom apps
- dbt Cloud personal credentials separate from project credentials — not obvious first time
- Example models must be deleted immediately after init

---

## Known Limitations of This Demo Stack
| Limitation | Impact | Fix for real client |
|---|---|---|
| No real COGS data | Margin % not accurate | Connect Lexoffice CSV export |
| No Google Ads spend data | No real ROAS calculation | Add Google Ads Airbyte connector |
| Sample data = 1 month only | Cohort analysis limited | Real store has 12+ months |
| Channel attribution simulated | Marketing page is illustrative | Real UTM data from Shopify |
| No currency conversion | Fine for EUR-only stores | Add FX rates table for multi-currency |