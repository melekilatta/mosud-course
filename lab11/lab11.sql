--Обычное представление v_order_summary
CREATE SCHEMA IF NOT EXISTS lab;

CREATE OR REPLACE VIEW lab.v_order_summary AS
SELECT o.order_id,
       o.order_purchase_timestamp,
       c.customer_state,
       COUNT(i.order_item_id) AS item_count,
       COALESCE(SUM(i.price + i.freight_value), 0) AS order_total
FROM olist.orders AS o
JOIN olist.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN olist.order_items AS i ON i.order_id = o.order_id
GROUP BY o.order_id, o.order_purchase_timestamp, c.customer_state;

--2. Материализованное представление по месяцам и штатам
CREATE MATERIALIZED VIEW lab.mv_monthly_state_sales AS
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       customer_state,
       COUNT(*) AS order_count,
       SUM(order_total) AS sales_total
FROM lab.v_order_summary
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date,
         customer_state;

--3. Аналитический запрос с тремя CTE
WITH monthly AS (
    SELECT month, customer_state, order_count, sales_total
    FROM lab.mv_monthly_state_sales
    WHERE customer_state IS NOT NULL
),
ranked AS (
    SELECT month, customer_state, order_count, sales_total,
           ROW_NUMBER() OVER (
               PARTITION BY month
               ORDER BY sales_total DESC, customer_state
           ) AS place
    FROM monthly
),
top_three AS (
    SELECT month, customer_state, order_count, sales_total, place
    FROM ranked
    WHERE place <= 3
)
SELECT month, place, customer_state, order_count, sales_total
FROM top_three
ORDER BY month, place;
--4. Создадим lab.geo_tree и заполним данными
CREATE TABLE lab.geo_tree (
    node_id text PRIMARY KEY,
    parent_id text REFERENCES lab.geo_tree (node_id),
    node_type text NOT NULL
        CHECK (node_type IN ('country', 'state', 'city')),
    node_name text NOT NULL
);

INSERT INTO lab.geo_tree (node_id, parent_id, node_type, node_name)
VALUES ('BR', NULL, 'country', 'Brazil');

INSERT INTO lab.geo_tree (node_id, parent_id, node_type, node_name)
SELECT DISTINCT 'ST:' || customer_state, 'BR', 'state', customer_state
FROM olist.customers
WHERE customer_state IS NOT NULL;

WITH ranked_cities AS (
    SELECT customer_state,
           customer_city,
           ROW_NUMBER() OVER (
               PARTITION BY customer_state
               ORDER BY COUNT(*) DESC, customer_city
           ) AS city_rank
    FROM olist.customers
    WHERE customer_state IS NOT NULL
      AND customer_city IS NOT NULL
    GROUP BY customer_state, customer_city
)
INSERT INTO lab.geo_tree (node_id, parent_id, node_type, node_name)
SELECT 'CT:' || customer_state || ':' || customer_city,
       'ST:' || customer_state,
       'city',
       customer_city
FROM ranked_cities
WHERE city_rank <= 20;

--5. Вывести поддерево штата GO
WITH RECURSIVE subtree AS (
    SELECT 0 AS depth, node_id, node_id AS path, node_name
    FROM lab.geo_tree
    WHERE node_id = 'ST:GO'

    UNION ALL

    SELECT s.depth + 1,
           n.node_id,
           s.path || ' - ' || n.node_id,
           n.node_name
    FROM subtree AS s
    JOIN lab.geo_tree AS n ON n.parent_id = s.node_id
)
SELECT depth, node_id, path, node_name
FROM subtree
ORDER BY depth, node_name;

--6. Вывести цепочку от города до BR
WITH RECURSIVE chosen_city AS (
    SELECT node_id, parent_id, node_name
    FROM lab.geo_tree
    WHERE parent_id = 'ST:GO'
      AND node_type = 'city'
    ORDER BY node_name
    LIMIT 1
),
ancestors AS (
    SELECT 0 AS depth, node_id, parent_id, node_name
    FROM chosen_city

    UNION ALL

    SELECT a.depth + 1, p.node_id, p.parent_id, p.node_name
    FROM ancestors AS a
    JOIN lab.geo_tree AS p ON p.node_id = a.parent_id
)
SELECT depth, node_id, node_name
FROM ancestors
ORDER BY depth;

--7. Посчитать потомков каждого штата
SELECT s.node_name AS state,
       COUNT(c.node_id) AS descendant_count
FROM lab.geo_tree AS s
LEFT JOIN lab.geo_tree AS c ON c.parent_id = s.node_id
WHERE s.node_type = 'state'
GROUP BY s.node_id, s.node_name
ORDER BY state;

--8. Дополнительно — создать цикл и защитить рекурсию
CREATE TEMP TABLE geo_tree_cycle AS
SELECT * FROM lab.geo_tree;

UPDATE geo_tree_cycle
SET parent_id = 'ST:GO'
WHERE node_id = 'BR';

WITH RECURSIVE ancestors AS (
    SELECT node_id, parent_id, ARRAY[node_id] AS visited
    FROM geo_tree_cycle
    WHERE node_id = 'BR'

    UNION ALL

    SELECT p.node_id, p.parent_id, a.visited || ARRAY[p.node_id]
    FROM ancestors AS a
    JOIN geo_tree_cycle AS p ON p.node_id = a.parent_id
    WHERE NOT (p.node_id = ANY(a.visited))
)
SELECT node_id, visited
FROM ancestors
ORDER BY CARDINALITY(visited);