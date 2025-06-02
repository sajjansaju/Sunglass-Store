select u.user_id,
        cast(sum(p.price) as decimal(10,2)) as lifetime_value
from {{ref('dim_users')}} u
join {{ref('fct_orders')}} o 
on u.user_id = o.user_id
join {{ref('dim_products')}} p
on p.item_id = o.item_id
group by u.user_id
order by lifetime_value desc;