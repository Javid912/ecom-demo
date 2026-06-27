# Pipeline Architecture

## Data Flow

```
Shopify Store
    │
    │  Admin API (orders, customers, products)
    ▼
Airbyte Cloud (free tier)
    │
    │  daily sync
    ▼
BigQuery — ecom_raw
    ├── orders          (line_items nested as JSON array)
    ├── customers
    ├── products
    └── order_refunds
    │
    │  dbt Cloud — daily job 06:00 UTC
    ▼
BigQuery — ecom_marts
    ├── stg_orders              (view — cleaned orders)
    ├── stg_order_lines         (view — unnested line items)
    ├── stg_customers           (view — cleaned customers)
    ├── mart_revenue_monthly    (table — revenue KPIs)
    ├── mart_marketing_performance (table — channel attribution)
    └── mart_customer_ltv       (table — customer segments)
    │
    │  direct BigQuery connection
    ▼
Looker Studio
    ├── Page 1: Revenue & Margin
    ├── Page 2: Customer LTV & Cohorts
    └── Page 3: Marketing Performance
```

## Stack

| Layer | Tool | Cost |
|-------|------|------|
| Source | Shopify API | Free (included in store) |
| Ingestion | Airbyte Cloud | Free tier |
| Warehouse | BigQuery (GCP) | Free tier |
| Transformation | dbt Cloud | Free Developer tier |
| Visualization | Looker Studio | Free |
| **Total** | | **~€0/mo for demo** |

## GCP Resources

- Project: `ecom-demo-488710`
- Raw dataset: `ecom_raw`
- Marts dataset: `ecom_marts`
- Dev dataset: `ecom_dev_marts`
- Region: EU

## Repository Structure

```
ecom-demo/
├── models/                          ← dbt models
│   ├── sources.yml                  ← declares raw BigQuery tables
│   ├── staging/
│   │   ├── stg_orders.sql
│   │   ├── stg_order_lines.sql
│   │   └── stg_customers.sql
│   └── marts/
│       ├── mart_revenue_monthly.sql
│       ├── mart_marketing_performance.sql
│       └── mart_customer_ltv.sql
├── seeds/
│   └── product_margins.csv
├── tests/                           ← dbt tests
├── macros/                          ← dbt macros
├── snapshots/                       ← dbt snapshots
├── docs/
│   ├── business/                    ← Business docs
│   └── product/                     ← Product docs
└── website/                         ← Landing page + cockpit
```

## Key Decisions

1. **dbt** for structured data modeling (staging → marts)
2. **BigQuery** for scalability and native Looker integration
3. **Airbyte Cloud** for no-maintenance ingestion
4. **EU region** for German client data compliance
5. **Views for staging** (cheap, always fresh), **tables for marts** (fast queries)
