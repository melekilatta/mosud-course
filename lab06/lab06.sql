--Решить задачу варианта с использованием хотя бы одного подзапроса.
WITH repeat_buyers AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.payment_value), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN olist.order_payments AS p ON p.order_id = o.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
)
SELECT customer_unique_id, total_spent
FROM repeat_buyers
WHERE total_spent > (SELECT AVG(total_spent) FROM repeat_buyers);

--Основной запрос с EXISTS и скалярным подзапросом
WITH repeat_buyers AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.payment_value), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN olist.order_payments AS p ON p.order_id = o.order_id
    WHERE EXISTS (
        SELECT 1
        FROM olist.customers AS c2
        JOIN olist.orders AS o2 ON o2.customer_id = c2.customer_id
        WHERE c2.customer_unique_id = c.customer_unique_id
          AND o2.order_id <> o.order_id
    )
    GROUP BY c.customer_unique_id
)
SELECT customer_unique_id, total_spent
FROM repeat_buyers
WHERE total_spent > (SELECT AVG(total_spent) FROM repeat_buyers)
ORDER BY total_spent DESC, customer_unique_id;

--Альтернативный запрос с предварительной агрегацией
WITH payments_by_order AS (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM olist.order_payments
    GROUP BY order_id
),
repeat_buyers AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.order_total), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN payments_by_order AS p ON p.order_id = o.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
),
average_spending AS (
    SELECT AVG(total_spent) AS avg_spent
    FROM repeat_buyers
)
SELECT r.customer_unique_id, r.total_spent
FROM repeat_buyers AS r
CROSS JOIN average_spending AS a
WHERE r.total_spent > a.avg_spent
ORDER BY r.total_spent DESC, r.customer_unique_id;

--Проверка через EXCEPT в обе стороны
WITH repeat_by_exists AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.payment_value), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN olist.order_payments AS p ON p.order_id = o.order_id
    WHERE EXISTS (
        SELECT 1
        FROM olist.customers AS c2
        JOIN olist.orders AS o2 ON o2.customer_id = c2.customer_id
        WHERE c2.customer_unique_id = c.customer_unique_id
          AND o2.order_id <> o.order_id
    )
    GROUP BY c.customer_unique_id
),
payments_by_order AS (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM olist.order_payments
    GROUP BY order_id
),
repeat_by_count AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.order_total), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN payments_by_order AS p ON p.order_id = o.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
),
main_result AS (
    SELECT customer_unique_id, total_spent
    FROM repeat_by_exists
    WHERE total_spent > (SELECT AVG(total_spent) FROM repeat_by_exists)
),
alternative_result AS (
    SELECT r.customer_unique_id, r.total_spent
    FROM repeat_by_count AS r
    CROSS JOIN (SELECT AVG(total_spent) AS avg_spent FROM repeat_by_count) AS a
    WHERE r.total_spent > a.avg_spent
)
SELECT 'main_minus_alternative' AS comparison, COUNT(*) AS difference_count
FROM (
    SELECT * FROM main_result
    EXCEPT
    SELECT * FROM alternative_result
) AS difference
UNION ALL
SELECT 'alternative_minus_main', COUNT(*)
FROM (
    SELECT * FROM alternative_result
    EXCEPT
    SELECT * FROM main_result
) AS difference;

--Пример с ANY
WITH repeat_buyers AS (
    SELECT c.customer_unique_id,
           COALESCE(SUM(p.payment_value), 0) AS total_spent
    FROM olist.customers AS c
    JOIN olist.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN olist.order_payments AS p ON p.order_id = o.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
)
SELECT customer_unique_id, total_spent
FROM repeat_buyers
WHERE total_spent > ANY (SELECT total_spent FROM repeat_buyers)
ORDER BY total_spent DESC, customer_unique_id;
