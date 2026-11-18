-- orders к customers: N:1 по customer_id
-- order_items к sellers: N:1 по seller_id. 
-- Заказы и продавцы связаны как M:N через order_items. 
-- orders к order_items, order_payments, order_reviews: 1:N в исходных данных.
-- После группировки по order_id каждый из трёх LEFT JOIN имеет кратность
-- 1:0..1. Заказ сохраняется, даже если у него нет позиций, оплат или отзывов.
WITH items_by_order AS (
    SELECT oi.order_id,
           COUNT(*) AS item_count,
           SUM(oi.price) AS items_total,
           SUM(oi.freight_value) AS freight_total,
           ARRAY_AGG(DISTINCT s.seller_id ORDER BY s.seller_id) AS seller_ids
    FROM olist.order_items AS oi
    JOIN olist.sellers AS s ON s.seller_id = oi.seller_id
    GROUP BY oi.order_id
),
payments_by_order AS (
    SELECT order_id,
           COUNT(*) AS payment_count,
           SUM(payment_value) AS payment_total
    FROM olist.order_payments
    GROUP BY order_id
),
reviews_by_order AS (
    SELECT order_id,
           COUNT(*) AS review_count,
           AVG(review_score) AS avg_review_score
    FROM olist.order_reviews
    GROUP BY order_id
)
SELECT o.order_id,
       o.order_status,
       c.customer_unique_id,
       c.customer_state,
       COALESCE(i.item_count, 0) AS item_count,
       i.items_total,
       i.freight_total,
       i.seller_ids,
       COALESCE(p.payment_count, 0) AS payment_count,
       p.payment_total,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_review_score
FROM olist.orders AS o
JOIN olist.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN items_by_order AS i ON i.order_id = o.order_id
LEFT JOIN payments_by_order AS p ON p.order_id = o.order_id
LEFT JOIN reviews_by_order AS r ON r.order_id = o.order_id
ORDER BY o.order_id;

--Реляционная алгебра
--I = γ_{order_id; COUNT(*), SUM(price), SUM(freight_value),
--        ARRAY_AGG(DISTINCT sellers.seller_id)}
--       (order_items ⋈_{order_items.seller_id = sellers.seller_id} sellers)
-- P = γ_{order_id; COUNT(*), SUM(payment_value)}(order_payments)
-- R = γ_{order_id; COUNT(*), AVG(review_score)}(order_reviews)
-- Паспорт = π_{столбцы итогового SELECT}
--   ((((orders ⋈_{orders.customer_id = customers.customer_id} customers)
--      ⟕_{orders.order_id = I.order_id} I)
--      ⟕_{orders.order_id = P.order_id} P)
--      ⟕_{orders.order_id = R.order_id} R)



-- 2. Антисоединение: заказы без единого отзыва.
SELECT o.order_id, o.order_status
FROM olist.orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM olist.order_reviews AS r
    WHERE r.order_id = o.order_id
)
ORDER BY o.order_id;

-- Ошибочный join
SELECT i.order_id,
       COUNT(DISTINCT i.order_item_id) AS item_count,
       COUNT(DISTINCT p.payment_sequential) AS payment_count,
       COUNT(*) AS joined_rows,
       SUM(i.price) AS inflated_items_total,
       SUM(p.payment_value) AS inflated_payment_total
FROM olist.order_items AS i
JOIN olist.order_payments AS p ON p.order_id = i.order_id
GROUP BY i.order_id
HAVING COUNT(DISTINCT i.order_item_id) > 1
   AND COUNT(DISTINCT p.payment_sequential) > 1
ORDER BY i.order_id
LIMIT 10;

--Исправленный ошибочный join
WITH items AS (
    SELECT order_id, COUNT(*) AS item_count, SUM(price) AS items_total
    FROM olist.order_items
    GROUP BY order_id
),
payments AS (
    SELECT order_id, COUNT(*) AS payment_count, SUM(payment_value) AS payment_total
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT i.order_id,
       i.item_count,
       p.payment_count,
       i.items_total,
       p.payment_total
FROM items AS i
JOIN payments AS p ON p.order_id = i.order_id
WHERE i.item_count > 1 AND p.payment_count > 1
ORDER BY i.order_id
LIMIT 10;