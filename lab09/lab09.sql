--Создать нормализованные таблицы
CREATE SCHEMA IF NOT EXISTS lab;

CREATE TABLE lab.nf_10_warehouses (
    warehouse_code text PRIMARY KEY,
    city text NOT NULL
);

CREATE TABLE lab.nf_10_products (
    product_id text PRIMARY KEY,
    category_name text NOT NULL
);

CREATE TABLE lab.nf_10_transfers (
    transfer_id integer PRIMARY KEY,
    source_wh text NOT NULL REFERENCES lab.nf_10_warehouses (warehouse_code),
    dest_wh text NOT NULL REFERENCES lab.nf_10_warehouses (warehouse_code),
    created_at timestamp NOT NULL
);

CREATE TABLE lab.nf_10_transfer_items (
    item_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_id integer NOT NULL REFERENCES lab.nf_10_transfers (transfer_id),
    product_id text NOT NULL REFERENCES lab.nf_10_products (product_id),
    qty integer NOT NULL,
    UNIQUE (transfer_id, product_id)
);

--Добавить три тестовые позиции и показать результат
INSERT INTO lab.nf_10_warehouses (warehouse_code, city)
VALUES ('W1', 'Сан-Паулу'),
       ('W2', 'Рио-де-Жанейро');

INSERT INTO lab.nf_10_products (product_id, category_name)
VALUES ('P1', 'Электроника'),
       ('P2', 'Мебель');

INSERT INTO lab.nf_10_transfers (transfer_id, source_wh, dest_wh, created_at)
VALUES (1, 'W1', 'W2', TIMESTAMP '2026-01-10 10:00:00'),
       (2, 'W2', 'W1', TIMESTAMP '2026-01-11 12:00:00');

INSERT INTO lab.nf_10_transfer_items (transfer_id, product_id, qty)
VALUES (1, 'P1', 5),
       (1, 'P2', 2),
       (2, 'P1', 3);
--Отдельный запрос восстанавливает исходное плоское представление:
SELECT t.transfer_id,
       t.source_wh,
       src.city AS source_city,
       t.dest_wh,
       dst.city AS dest_city,
       i.product_id,
       p.category_name,
       i.qty,
       t.created_at
FROM lab.nf_10_transfer_items AS i
JOIN lab.nf_10_transfers AS t ON t.transfer_id = i.transfer_id
JOIN lab.nf_10_products AS p ON p.product_id = i.product_id
JOIN lab.nf_10_warehouses AS src ON src.warehouse_code = t.source_wh
JOIN lab.nf_10_warehouses AS dst ON dst.warehouse_code = t.dest_wh
ORDER BY t.transfer_id, i.product_id;