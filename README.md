# Ecom-Demo — Shopify Analytics Pipeline

End-to-end analytics system: **Shopify → Airbyte → BigQuery → dbt → Looker Studio**.

Built as a productized service for €1M–€10M revenue Shopify stores.
Part of an analytics agency targeting €100K+ net revenue.

---

## Quick Links

| Link | Where |
|---|---|
| **Cockpit** (project hub) | [`website/cockpit.html`](website/cockpit.html) — also on [GitHub Pages](https://Javid912.github.io/ecom-demo/cockpit.html) |
| Pipeline architecture | [`docs/product/01-architecture.md`](docs/product/01-architecture.md) |
| Build checklist | [`docs/product/02-build-checklist.md`](docs/product/02-build-checklist.md) |
| Business plan | [`docs/business/01-business-plan.md`](docs/business/01-business-plan.md) |
| Service packages | [`docs/business/02-services-packages.md`](docs/business/02-services-packages.md) |
| Pricing model | [`docs/business/03-pricing.md`](docs/business/03-pricing.md) |
| Marketing strategy | [`docs/business/04-marketing-strategy.md`](docs/business/04-marketing-strategy.md) |

---

## Repository Structure

```
ecom-demo/
├── models/                     ← dbt models (staging → marts)
│   ├── sources.yml             source definitions + tests
│   ├── staging/                staging views (cleaned raw data)
│   └── marts/                  mart tables (business KPIs)
├── seeds/                      dbt seed data (product_margins.csv)
├── tests/                      dbt tests
├── macros/                     dbt macros
├── snapshots/                  dbt snapshots (SCD tracking)
├── docs/
│   ├── business/               business plan, services, pricing, marketing
│   ├── product/                architecture, checklist, changelog
│   └── decisions/              architecture decision records
├── website/                    landing page + internal cockpit
│   ├── cockpit.html            project dashboard (open this first)
│   └── assets/                 CSS, JS, images
├── dbt_project.yml             dbt project configuration
└── README.md
```

---

## Pipeline

```
Shopify → Airbyte Cloud → BigQuery (ecom_raw) → dbt Cloud → BigQuery (ecom_marts) → Looker Studio
```

| Layer | Tool | Cost |
|---|---|---|
| Source | Shopify API | Free |
| Ingestion | Airbyte Cloud | Free tier |
| Warehouse | BigQuery | Free tier |
| Transform | dbt Cloud | Free Developer |
| Visualize | Looker Studio | Free |

**GCP Project:** `ecom-demo-488710` · Region: EU

---

## dbt Models

| Model | Type | Purpose |
|---|---|---|
| `stg_orders` | view | Clean orders, extract customer JSON |
| `stg_order_lines` | view | Unnest line items from JSON array |
| `stg_customers` | view | Clean customers, parse tags |
| `mart_revenue_monthly` | table | Monthly revenue, AOV, volume |
| `mart_marketing_performance` | table | Channel attribution, ROAS |
| `mart_customer_ltv` | table | LTV segments, repeat buyer flags |

---

## Business Model

Productized analytics service for mid-market Shopify stores.

| Tier | Setup | Monthly | Target |
|---|---|---|---|
| Starter | €3K | €500/mo | €1M–€3M stores |
| Growth | €5K | €1K/mo | €3M–€5M stores |
| Enterprise | €8K | €2K/mo | €5M–€10M stores |

---

## Branches

- `main` — stable, production-ready
- `develop` — active development (you are here)

---

## Changelog

| Version | Date | Notes |
|---|---|---|
| v1.0 | March 2026 | Initial build — Egnition sample data |
| v1.1 | June 2026 | Repo restructured, business docs, cockpit, develop branch |

---

## Author

Built by Javad — data engineering consultant, Berlin.  
Specializing in e-commerce analytics for German SMEs.
