--Найти категории через двойной NOT EXISTS
WITH target_states(state) AS (
    VALUES ('AL'), ('SE'), ('BA')
),
sales AS (
    SELECT p.product_category_name AS category,
           c.customer_state AS state
    FROM olist.order_items AS i
    JOIN olist.products AS p ON p.product_id = i.product_id
    JOIN olist.orders AS o ON o.order_id = i.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT DISTINCT p.product_category_name AS category
FROM olist.products AS p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM target_states AS t
      WHERE NOT EXISTS (
          SELECT 1
          FROM sales AS s
          WHERE s.category = p.product_category_name
            AND s.state = t.state
      )
  )
ORDER BY category;

--Реализовать то же через GROUP BY/HAVING COUNT (DISTINCT customer_state).
WITH target_states(state) AS (
    VALUES ('AL'), ('SE'), ('BA')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sales AS (
    SELECT p.product_category_name AS category,
           c.customer_state
    FROM olist.order_items AS i
    JOIN olist.products AS p ON p.product_id = i.product_id
    JOIN olist.orders AS o ON o.order_id = i.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state IN (SELECT state FROM target_states)
)
SELECT c.category
FROM categories AS c
LEFT JOIN sales AS s ON s.category = c.category
GROUP BY c.category
HAVING COUNT(DISTINCT s.customer_state) = (SELECT COUNT(*) FROM target_states)
ORDER BY c.category;

--Черезе except и not exist
WITH target_states(state) AS (
    VALUES ('AL'), ('SE'), ('BA')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sales AS (
    SELECT p.product_category_name AS category,
           c.customer_state AS state
    FROM olist.order_items AS i
    JOIN olist.products AS p ON p.product_id = i.product_id
    JOIN olist.orders AS o ON o.order_id = i.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT c.category
FROM categories AS c
WHERE NOT EXISTS (
    SELECT state FROM target_states
    EXCEPT
    SELECT s.state FROM sales AS s
    WHERE s.category = c.category
)
ORDER BY c.category;

--Сравнить множества результатов оператором EXCEPT в обе стороны и доказать их эквивалентность на данных.
WITH target_states(state) AS (
    VALUES ('AL'), ('SE'), ('BA')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sales AS (
    SELECT p.product_category_name AS category,
           c.customer_state AS state
    FROM olist.order_items AS i
    JOIN olist.products AS p ON p.product_id = i.product_id
    JOIN olist.orders AS o ON o.order_id = i.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
by_exists AS (
    SELECT c.category
    FROM categories AS c
    WHERE NOT EXISTS (
        SELECT 1
        FROM target_states AS t
        WHERE NOT EXISTS (
            SELECT 1
            FROM sales AS s
            WHERE s.category = c.category AND s.state = t.state
        )
    )
),
by_count AS (
    SELECT c.category
    FROM categories AS c
    LEFT JOIN sales AS s ON s.category = c.category
        AND s.state IN (SELECT state FROM target_states)
    GROUP BY c.category
    HAVING COUNT(DISTINCT s.state) = (SELECT COUNT(*) FROM target_states)
),
by_except AS (
    SELECT c.category
    FROM categories AS c
    WHERE NOT EXISTS (
        SELECT state FROM target_states
        EXCEPT
        SELECT s.state FROM sales AS s WHERE s.category = c.category
    )
)
SELECT
    (SELECT COUNT(*) FROM (
        SELECT category FROM by_exists
        EXCEPT
        SELECT category FROM by_count
    ) AS diff) AS exists_minus_count,
    (SELECT COUNT(*) FROM (
        SELECT category FROM by_count
        EXCEPT
        SELECT category FROM by_exists
    ) AS diff) AS count_minus_exists,
    (SELECT COUNT(*) FROM (
        SELECT category FROM by_exists
        EXCEPT
        SELECT category FROM by_except
    ) AS diff) AS exists_minus_except,
    (SELECT COUNT(*) FROM (
        SELECT category FROM by_except
        EXCEPT
        SELECT category FROM by_exists
    ) AS diff) AS except_minus_exists;
    --EXCEPT в обоих направлениях вернул пустые разности для каждой пары.

--Для одной найденной категории вывести диагностическую таблицу: категория → штат → число заказов.
WITH sales AS (
    SELECT p.product_category_name AS category,
           c.customer_state AS state,
           o.order_id
    FROM olist.order_items AS i
    JOIN olist.products AS p ON p.product_id = i.product_id
    JOIN olist.orders AS o ON o.order_id = i.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND c.customer_state IN ('AL', 'SE', 'BA')
),
chosen_category AS (
    SELECT category
    FROM sales
    GROUP BY category
    HAVING COUNT(DISTINCT state) = 3
    ORDER BY category
    LIMIT 1
)
SELECT category, state, COUNT(DISTINCT order_id) AS order_count
FROM sales
WHERE category = (SELECT category FROM chosen_category)
GROUP BY category, state
ORDER BY state;
--Версия пустого CTE
WITH target_states(state) AS (
    SELECT ''::text
    WHERE FALSE
),
--вернулись все категории с ненулевым названием.
--Логика простая: условие «категория продавалась в каждом обязательном штате» выполнено, потому что обязательных штатов нет и ни один из них не может нарушить условие.
