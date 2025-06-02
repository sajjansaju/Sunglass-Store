select o.user_id,
        case
            when COUNT(DISTINCT o.order_id) > 1 THEN 'Yes'
            ELSE 'No'
        end as repeat_customer
from {{ref('fct_orders')}} o 
group by o.user_id