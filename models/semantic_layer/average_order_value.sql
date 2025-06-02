select cast(SUM(p.price)/ count(o.order_id) as decimal(10,2)) as avg_order_value
from {{ ref('fct_orders') }} o
join {{ ref('dim_products')}} p
on o.item_id = p.item_id