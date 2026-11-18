SELECT 'customers' AS table_name, count(*) FROM olist.customers
UNION ALL SELECT 'orders', count(*) FROM olist.orders
UNION ALL SELECT 'order_items', count(*) FROM olist.order_items;

--Результат:
--table_name |count |
-- ---------+------+
--order_items|112650|
--orders     | 99441|
--customers  | 99441|

SELECT count(*) AS orphan_items
FROM olist.order_items oi
LEFT JOIN olist.orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

--Результат
--orphan_items|
-- ----------+
--           0|