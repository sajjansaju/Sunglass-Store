{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ref('orders_cleaned')}}
{% if is_incremental() %}
    where order_id > (select max(order_id) from {{this}})
{% endif %}