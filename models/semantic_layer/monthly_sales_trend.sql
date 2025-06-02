select dd.month,
        cast(sum(p.price) as decimal(10,2)) as total_revenue
from {{ref('dim_dates')}} dd
join {{ref('fct_orders')}} o 
on o.purchase_date = dd.date_actual
join {{ref('dim_products')}} p 
on p.item_id = o.item_id
group by dd.month
order by month 