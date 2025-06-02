select u.user_id,
        u.join_date,
        min(o.purchase_date) as first_purchase_date,
        date_diff('day',u.join_date, min(o.purchase_date)) as days_to_first_purchase
from {{ref('dim_users')}} u
join {{ref('fct_orders')}} o 
on o.user_id= u.user_id
group by u.user_id,
            u.join_date
order by days_to_first_purchase desc