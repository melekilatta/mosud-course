--Подсчитать NULL в трёх таблицах
--orders
SELECT
    COUNT(*) - COUNT(order_status) AS null_status,
    COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase_date,
    COUNT(*) - COUNT(order_approved_at) AS null_approved_date,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS null_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_delivery_date,
    COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated_date
FROM olist.orders;

--products
SELECT
    COUNT(*) - COUNT(product_category_name) AS null_category,
    COUNT(*) - COUNT(product_name_lenght) AS null_name_length,
    COUNT(*) - COUNT(product_description_lenght) AS null_description_length,
    COUNT(*) - COUNT(product_photos_qty) AS null_photos_qty,
    COUNT(*) - COUNT(product_weight_g) AS null_weight,
    COUNT(*) - COUNT(product_length_cm) AS null_length,
    COUNT(*) - COUNT(product_height_cm) AS null_height,
    COUNT(*) - COUNT(product_width_cm) AS null_width
FROM olist.products;

--order_reviews
SELECT
    COUNT(*) - COUNT(review_score) AS null_score,
    COUNT(*) - COUNT(review_comment_title) AS null_title,
    COUNT(*) - COUNT(review_comment_message) AS null_message,
    COUNT(*) - COUNT(review_creation_date) AS null_creation_date,
    COUNT(*) - COUNT(review_answer_timestamp) AS null_answer_date
FROM olist.order_reviews;

--Сравнить COUNT(*) и COUNT(order_delivered_customer_date)
SELECT COUNT(*) AS total_orders,
       COUNT(order_delivered_customer_date) AS orders_with_delivery_date,
       COUNT(*) - COUNT(order_delivered_customer_date) AS orders_without_delivery_date
FROM olist.orders;
--Первое число — все заказы. Второе — заказы с указанной фактической датой доставки. Третье показывает, у скольких заказов дата отсутствует.

--Сравнить = NULL, <> NULL и правильные проверки
SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date = NULL) AS equals_null,
    COUNT(*) FILTER (WHERE order_delivered_customer_date <> NULL) AS not_equals_null,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS is_null,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL) AS is_not_null
FROM olist.orders;

--Проверить IS DISTINCT FROM
SELECT a, b,
       a <> b AS ordinary_comparison,
       a IS DISTINCT FROM b AS null_safe_comparison
FROM (VALUES (5, 5), (5, NULL), (NULL, NULL)) AS pairs(a, b);

--Сравнить NOT IN и NOT EXISTS
CREATE TEMP TABLE temp_ids (id text);

INSERT INTO temp_ids (id)
SELECT order_id
FROM olist.orders
ORDER BY order_id
LIMIT 1;

INSERT INTO temp_ids (id) VALUES (NULL);

SELECT
    COUNT(*) FILTER (
        WHERE o.order_id NOT IN (SELECT id FROM temp_ids)
    ) AS not_in_count,
    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM temp_ids AS t
            WHERE t.id = o.order_id
        )
    ) AS not_exists_count
FROM olist.orders AS o;

--Сравнить фильтр в ON и в WHERE
SELECT COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders AS o
LEFT JOIN olist.order_reviews AS r
    ON r.order_id = o.order_id
   AND r.review_score >= 4;

--Фильтр в WHERE
SELECT COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders AS o
LEFT JOIN olist.order_reviews AS r ON r.order_id = o.order_id
WHERE r.review_score >= 4;

--Использовать COALESCE и NULLIF
--Подставить текст вместо отсутствующего комментария
SELECT review_id,
       COALESCE(review_comment_message, 'Без комментария') AS comment_text
FROM olist.order_reviews
WHERE review_comment_message IS NULL
LIMIT 10;

--Показать безопасное деление
SELECT 10.0 / NULLIF(2, 0) AS normal_result,
       10.0 / NULLIF(0, 0) AS zero_denominator_result;

--Вывести профиль качества данных
SELECT 'Заказы без фактической даты доставки' AS metric,
       ROUND(100.0 * (COUNT(*) - COUNT(order_delivered_customer_date))
             / NULLIF(COUNT(*), 0), 2) AS percent
FROM olist.orders

UNION ALL

SELECT 'Товары без категории',
       ROUND(100.0 * (COUNT(*) - COUNT(product_category_name))
             / NULLIF(COUNT(*), 0), 2)
FROM olist.products

UNION ALL

SELECT 'Отзывы без текста комментария',
       ROUND(100.0 * (COUNT(*) - COUNT(review_comment_message))
             / NULLIF(COUNT(*), 0), 2)
FROM olist.order_reviews;

--Привести пример естественного пропуска и проблемы качества
SELECT 'Отменённые заказы без даты доставки' AS example,
       COUNT(*) AS row_count
FROM olist.orders
WHERE order_status = 'canceled'
  AND order_delivered_customer_date IS NULL

UNION ALL

SELECT 'Товары без категории', COUNT(*)
FROM olist.products
WHERE product_category_name IS NULL;