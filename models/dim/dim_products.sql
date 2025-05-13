{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ ref('products_cleaned') }}
{% if is_incremental() %}
    where item_id > (select max(item_id) from {{this}})
{% endif %}