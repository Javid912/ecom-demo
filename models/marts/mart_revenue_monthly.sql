with orders as (
    select * from {{ ref('stg_orders') }}
    where is_completed = true
),

lines as (
    select * from {{ ref('stg_order_lines') }}
    where is_completed = true
),

order_totals as (
    select
        order_id,
        sum(line_total)                         as items_total,
        sum(quantity)                           as total_items,
        count(distinct product_id)              as unique_products
    from lines
    group by 1
),

monthly as (
    select
        o.order_month,
        format_date('%B %Y', o.order_month)     as month_label,

        -- Volume
        count(distinct o.order_id)              as total_orders,
        count(distinct o.customer_id)           as unique_customers,
        sum(ot.total_items)                     as total_items_sold,

        -- Revenue
        round(sum(o.total_price), 2)            as gross_revenue,
        round(sum(o.total_discounts), 2)        as total_discounts,
        round(sum(o.total_price)
            - sum(o.total_discounts), 2)        as net_revenue,
        round(sum(o.total_tax), 2)              as total_tax,

        -- AOV
        round(avg(o.total_price), 2)            as avg_order_value,

        -- Geography
        approx_top_count(o.billing_country, 3)  as top_countries,
        approx_top_count(o.billing_city, 3)     as top_cities

    from orders o
    left join order_totals ot on o.order_id = ot.order_id
    group by 1, 2
)

select * from monthly
order by order_month
