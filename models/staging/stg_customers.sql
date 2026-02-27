with source as (
    select * from {{ source('ecom_raw', 'customers') }}
),

cleaned as (
    select
        cast(id as string)                                      as customer_id,
        email,
        cast(created_at as timestamp)                           as created_at,
        date(created_at)                                        as first_seen_date,
        date_trunc(date(created_at), month)                     as acquisition_month,

        -- Parse name from JSON default_address
        JSON_VALUE(default_address, '$.first_name')             as first_name,
        JSON_VALUE(default_address, '$.last_name')              as last_name,
        JSON_VALUE(default_address, '$.city')                   as city,
        JSON_VALUE(default_address, '$.country_code')           as country_code,

        -- Tags for segmentation
        tags,
        case
            when lower(tags) like '%vip%'      then true
            else false
        end                                                     as is_vip,
        case
            when lower(tags) like '%referral%' then true
            else false
        end                                                     as is_referral

    from source
    where id is not null
)

select * from cleaned
