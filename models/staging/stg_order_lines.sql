with orders as (
    select
        order_id,
        order_date,
        order_month,
        is_completed
    from {{ ref('stg_orders') }}
    where line_items is not null
),

source as (
    select * from {{ source('ecom_raw', 'orders') }}
    where id is not null
    and deleted_at is null
),

unnested as (
    select
        cast(o.id as string)                                    as order_id,
        date(o.created_at)                                      as order_date,
        date_trunc(date(o.created_at), month)                   as order_month,
        case
            when o.financial_status = 'paid' then true
            else false
        end                                                     as is_completed,

        -- Extract each line item field from JSON array
        JSON_VALUE(line_item, '$.id')                           as line_item_id,
        JSON_VALUE(line_item, '$.product_id')                   as product_id,
        JSON_VALUE(line_item, '$.variant_id')                   as variant_id,
        JSON_VALUE(line_item, '$.title')                        as product_title,
        JSON_VALUE(line_item, '$.sku')                          as sku,
        JSON_VALUE(line_item, '$.vendor')                       as vendor,
        cast(JSON_VALUE(line_item, '$.quantity') as int64)      as quantity,
        cast(JSON_VALUE(line_item, '$.price') as numeric)       as unit_price,
        cast(JSON_VALUE(line_item, '$.total_discount')
            as numeric)                                         as total_discount,

        -- Calculated
        cast(JSON_VALUE(line_item, '$.quantity') as int64)
        * cast(JSON_VALUE(line_item, '$.price') as numeric)     as line_total

    from source o,
    UNNEST(JSON_EXTRACT_ARRAY(o.line_items)) as line_item
)

select * from unnested
