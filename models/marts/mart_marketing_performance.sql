with orders as (
    select * from {{ ref('stg_orders') }}
    where is_completed = true
),

lines as (
    select * from {{ ref('stg_order_lines') }}
    where is_completed = true
),

-- Revenue and items per order
order_revenue as (
    select
        order_id,
        sum(line_total)     as items_revenue,
        sum(quantity)       as total_items
    from lines
    group by 1
),

-- Attribution: group source_name into readable channels
-- In real client: this joins to Google Ads spend data
-- For demo: we use Shopify's source_name field as proxy
orders_with_channel as (
    select
        o.order_id,
        o.order_month,
        o.order_date,
        o.customer_id,
        o.total_price,
        o.total_discounts,
        or_.items_revenue,
        or_.total_items,

        -- Channel grouping from Shopify source
case
    when o.source_name = 'web'              then 'Organic / Direct'
    when o.source_name like '%google%'      then 'Google'
    when o.source_name like '%meta%'        then 'Meta'
    when o.source_name like '%facebook%'    then 'Meta'
    when o.source_name is null              then 'Organic / Direct'
    when o.source_name like '%160%'         then 'Sample Data / Unknown'
    else 'Other: ' || o.source_name
end                                         as channel,

        -- Customer tags as acquisition signal
        case
            when lower(o.tags) like '%vip%'     then true
            else false
        end                                     as is_vip_order,
        case
            when lower(o.tags) like '%referral%' then true
            else false
        end                                     as is_referral

    from orders o
    left join order_revenue or_ on o.order_id = or_.order_id
),

monthly_by_channel as (
    select
        order_month,
        channel,

        -- Volume
        count(distinct order_id)                as total_orders,
        count(distinct customer_id)             as unique_customers,
        sum(total_items)                        as items_sold,

        -- Revenue
        round(sum(total_price), 2)              as gross_revenue,
        round(avg(total_price), 2)              as avg_order_value,
        round(sum(total_discounts), 2)          as total_discounts,

        -- Acquisition signals
        countif(is_vip_order)                   as vip_orders,
        countif(is_referral)                    as referral_orders

    from orders_with_channel
    group by 1, 2
)

select
    *,
    -- Share of revenue per channel
    round(
        gross_revenue / nullif(
            sum(gross_revenue) over (partition by order_month)
        , 0)
    , 4)                                        as revenue_share_pct

from monthly_by_channel
order by order_month, gross_revenue desc