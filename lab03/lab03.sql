--Выражение в sql
SELECT product_id,
       product_category_name AS category,
       product_length_cm AS length,
       product_height_cm AS height,
       product_width_cm AS width
FROM olist.products
WHERE product_category_name IS NOT NULL
  AND product_length_cm * product_height_cm * product_width_cm > 20000;

  -- Разобъем сложный предикат на две последовательные выборки и посмотрем эквивалентность реза
  WITH original AS (
    SELECT product_id,
           product_category_name AS category,
           product_length_cm AS length,
           product_height_cm AS height,
           product_width_cm AS width
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND product_length_cm * product_height_cm * product_width_cm > 20000
),
with_category AS (
    SELECT product_id,
           product_category_name AS category,
           product_length_cm AS length,
           product_height_cm AS height,
           product_width_cm AS width
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sequential AS (
    SELECT product_id, category, length, height, width
    FROM with_category
    WHERE length * height * width > 20000
)
(SELECT * FROM original EXCEPT SELECT * FROM sequential)
UNION ALL
(SELECT * FROM sequential EXCEPT SELECT * FROM original);
--Ожидаемо 0 строк так как они одинаковы

--Создадим второй SQL-вариант, в котором ненужные столбцы исключаются раньше.
WITH projected AS (
    SELECT product_id,
           product_category_name AS category,
           product_length_cm AS length,
           product_height_cm AS height,
           product_width_cm AS width
    FROM olist.products
),
with_category AS (
    SELECT product_id, category, length, height, width
    FROM projected
    WHERE category IS NOT NULL
)
SELECT product_id, category, length, height, width
FROM with_category
WHERE length * height * width > 20000;

--Проверим, могут ли в проекции возникнуть дубликаты. Для этого сравним select и select distinct
with original as (
	SELECT product_id,
       	product_category_name AS category,
       	product_length_cm AS length,
       	product_height_cm AS height,
       	product_width_cm AS width
	FROM olist.products
	WHERE product_category_name IS NOT NULL
  		AND product_length_cm * product_height_cm * product_width_cm > 20000
),

uniq as (
	SELECT distinct product_id,
       product_category_name AS category,
       product_length_cm AS length,
       product_height_cm AS height,
       product_width_cm AS width
	FROM olist.products
	WHERE product_category_name IS NOT NULL
  		AND product_length_cm * product_height_cm * product_width_cm > 20000
)

SELECT
    (SELECT COUNT(*) FROM original) AS total_rows,
    (SELECT COUNT(*) FROM uniq) AS distinct_rows;
-- Результат - одинаковое кол-во строк 7607