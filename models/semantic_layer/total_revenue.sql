SELECT
  cast(round(SUM(p.price),2) as decimal(16,2)) AS total_revenue
FROM fct_orders o
JOIN dim_products p ON o.item_id = p.item_id;