--Варинат 10

--Множество А
SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o ON o.order_id = oi.order_id
JOIN olist.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'MA';

--С подсчетом строк
SELECT count(*) as "total", COUNT(DISTINCT product_id) as "uniq"
FROM olist.order_items AS oi
JOIN olist.orders AS o ON o.order_id = oi.order_id
JOIN olist.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'MA'
--Результат
--total|uniq|
-------+----+
--  800| 657|

--Множество B
SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o ON o.order_id = oi.order_id
JOIN olist.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'PI';

--С подсчетом строк
SELECT count(*) as "total", COUNT(DISTINCT product_id) as "uniq"
FROM olist.order_items AS oi
JOIN olist.orders AS o ON o.order_id = oi.order_id
JOIN olist.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'PI'
--Результат
--total|uniq|
-------+----+
--  523| 446|

--A ∪ B с помощью UNION 
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS union_count
FROM (
    SELECT product_id FROM a
    UNION
    SELECT product_id FROM b
) AS combined;
--Результат:
--union_count|
-------------+
--       1046|

--A ∪ B с помощью UNION ALL
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS union_count
FROM (
    SELECT product_id FROM a
    union all
    SELECT product_id FROM b
) AS combined;
--Результат:
--union_count|
-------------+
--       1323|

--Если один product_id встречается несколько раз, 
--UNION оставляет его один раз, а UNION ALL сохраняет все появления.
--поэтому union all дал больше строк

--A ∩ B с помощью INTERSECT

WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS intersect_count
FROM (
    SELECT product_id FROM a
    INTERSECT
    SELECT product_id FROM b
) AS combined;
--Результат
--intersect_count|
-------------+
--         57|

--Получить A − B c помощью EXCEPT
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS except_count
FROM (
    SELECT product_id FROM a
    EXCEPT
    SELECT product_id FROM b
) AS combined;
--Результат
--except_count|
--------------+
--         600|

--Получить B − A c помощью EXCEPT
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS except_count
FROM (
    SELECT product_id FROM b
    EXCEPT
    SELECT product_id FROM a
) AS combined;
--Результат
--except_count|
--------------+
--         389|

--Следовательно разность некоммутативна, так как поменяв местами a и b мы получили равный результат

-- Проверка коммутативости объединения
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS union_count
FROM (
    SELECT product_id FROM b
    union
    SELECT product_id FROM a
) AS combined;
--Результат:
--union_count|
-------------+
--       1046|

--Следовательно объединение коммутативно, так как результат при a U b и b U a одинаковый


--Проверить коммутативность пересечения данных
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(*) AS intersect_count
FROM (
    SELECT product_id FROM b
    INTERSECT
    SELECT product_id FROM a
) AS combined;
--Результат
--intersect_count|
-------------+
--         57|

--Следовательно пересечение коммутативно, так как результат при a ∩ b и b ∩ a одинаковый

--Переписать пересечение без INTERSECT, используя EXISTS.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT COUNT(DISTINCT a.product_id) AS intersection_count
FROM a
WHERE EXISTS (
    SELECT 1
    FROM b
    WHERE b.product_id = a.product_id
);
--Результат
--intersection_count|
--------------------+
--               57|

--Для одного результата намеренно убрать DISTINCT/UNION и продемонстрировать появление дубликатов
--Возьмем объединение A и B и заменим UNION на UNION ALL
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'MA'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND c.customer_state = 'PI'
)
SELECT product_id, COUNT(*) AS occurrences
FROM (
    SELECT product_id FROM a
    UNION ALL
    SELECT product_id FROM b
) AS combined
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, product_id;
--Часть реззультата
--product_id                      |occurrences|
----------------------------------+-----------+
--bb50f2e236e5eea0100680137654686c|          9|
--389d119b48cf3043d311335e499d9c6b|          8|
--3dd2a17168ec895c781a9191c1e95ad7|          7|
--3fbc0ef745950c7932d5f2a446189725|          7|


--Выводы
--UNION, INTERSECT и EXCEPT удаляют дубликаты и возвращают множество строк.
--UNION ALL, INTERSECT ALL и EXCEPT ALL учитывают кратность строк,
--поэтому могут вернуть мультимножество, в котором строки повторяются.
--SELECT DISTINCT удаляет повторы, а обычный SELECT может их сохранять.
--В запросе с EXISTS условие проверяет наличие товара в B.
--Повторы товаров из A удаляет DISTINCT.