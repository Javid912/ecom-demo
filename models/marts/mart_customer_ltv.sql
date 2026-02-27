with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
    where is_completed = true
),

lines as (
    select * from {{ ref('stg_order_lines') }}
    where is_completed = true
),

-- Total revenue and order stats per customer
customer_orders as (
    select
        o.customer_id,
        count(distinct o.order_id)              as total_orders,
        min(o.order_date)                       as first_order_date,
        max(o.order_date)                       as last_order_date,
        round(sum(o.total_price), 2)            as total_revenue,
        round(avg(o.total_price), 2)            as avg_order_value,
        date_diff(
            max(o.order_date),
            min(o.order_date),
            day
        )                                       as days_between_first_last,
        sum(l.quantity)                         as total_items_bought,
        count(distinct l.product_id)            as unique_products_bought,
        -- Most purchased vendor
        approx_top_count(l.vendor, 1)[offset(0)].value
                                                as top_vendor
    from orders o
    left join lines l on o.order_id = l.order_id
    group by 1
),

final as (
    select
        c.customer_id,
        c.email,
        c.first_name,
        c.last_name,
        c.city,
        c.country_code,
        c.acquisition_month,
        c.is_vip,
        c.is_referral,
        c.tags,

        -- Order stats
        coalesce(co.total_orders, 0)            as total_orders,
        co.first_order_date,
        co.last_order_date,
        coalesce(co.total_revenue, 0)           as total_revenue,
        coalesce(co.avg_order_value, 0)         as avg_order_value,
        coalesce(co.days_between_first_last, 0) as days_active,
        coalesce(co.total_items_bought, 0)      as total_items_bought,
        coalesce(co.unique_products_bought, 0)  as unique_products_bought,
        co.top_vendor,

        -- LTV segments
        case
            when coalesce(co.total_revenue, 0) >= 200   then 'High Value'
            when coalesce(co.total_revenue, 0) >= 80    then 'Mid Value'
            when coalesce(co.total_revenue, 0) > 0      then 'Low Value'
            else 'No Purchase'
        end                                     as ltv_tier,

        -- Repeat buyer flag
        case
            when coalesce(co.total_orders, 0) > 1 then true
            else false
        end                                     as is_repeat_buyer

    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)

select * from final