with source as (
    select * from {{ source('ecom_raw', 'orders') }}
),

cleaned as (
    select
        -- IDs
        cast(id as string)                                  as order_id,
        cast(JSON_VALUE(customer, '$.id') as string)        as customer_id,

        -- Dates
        created_at                                          as created_at,
        date(created_at)                                    as order_date,
        date_trunc(date(created_at), month)                 as order_month,

        -- Status
        financial_status,
        fulfillment_status,
        case
            when financial_status = 'paid' then true
            else false
        end                                                 as is_completed,

        -- Money (already NUMERIC, no cast needed)
        total_price,
        subtotal_price,
        total_discounts,
        total_tax,
        currency,

        -- Location from JSON
        JSON_VALUE(billing_address, '$.city')               as billing_city,
        JSON_VALUE(billing_address, '$.country_code')       as billing_country,

        -- Raw JSON for downstream models
        line_items,

        -- Segmentation
        tags,
        source_name,
        landing_site

    from source
    where id is not null
        and deleted_at is null
)

select * from cleaned