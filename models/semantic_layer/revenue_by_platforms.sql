select u.from_platform,
        cast(sum(p.price) as decimal(10,2)) as total_revenue
from {{ref('dim_users')}} u 
join {{ref('fct_orders')}} o 
on o.user_id = u.user_id
join {{'dim_products'}} p 
on p.item_id = o.item_id
group by u.from_platform