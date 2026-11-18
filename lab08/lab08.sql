--Создадим схему
CREATE TABLE lab.warehouses (
    warehouse_code text,
    warehouse_name text NOT NULL,
    CONSTRAINT pk_warehouses PRIMARY KEY (warehouse_code),
    CONSTRAINT uq_warehouses_name UNIQUE (warehouse_name)
);

CREATE TABLE lab.inventory (
    warehouse_code text,
    product_id text,
    quantity integer NOT NULL,
    CONSTRAINT pk_inventory PRIMARY KEY (warehouse_code, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_code)
        REFERENCES lab.warehouses (warehouse_code),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES olist.products (product_id),
    CONSTRAINT ck_inventory_quantity CHECK (quantity >= 0)
);

CREATE TABLE lab.transfers (
    transfer_id integer,
    source_code text NOT NULL,
    destination_code text NOT NULL,
    transfer_date date NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_transfers PRIMARY KEY (transfer_id),
    CONSTRAINT fk_transfers_source FOREIGN KEY (source_code)
        REFERENCES lab.warehouses (warehouse_code),
    CONSTRAINT fk_transfers_destination FOREIGN KEY (destination_code)
        REFERENCES lab.warehouses (warehouse_code),
    CONSTRAINT ck_transfers_different_warehouses
        CHECK (source_code <> destination_code)
);

CREATE TABLE lab.transfer_items (
    transfer_id integer,
    product_id text,
    quantity integer NOT NULL,
    CONSTRAINT pk_transfer_items PRIMARY KEY (transfer_id, product_id),
    CONSTRAINT fk_transfer_items_transfer FOREIGN KEY (transfer_id)
        REFERENCES lab.transfers (transfer_id),
    CONSTRAINT fk_transfer_items_product FOREIGN KEY (product_id)
        REFERENCES olist.products (product_id),
    CONSTRAINT ck_transfer_items_quantity CHECK (quantity > 0)
);

--Добавим данные
INSERT INTO lab.warehouses (warehouse_code, warehouse_name)
VALUES ('W1', 'Центральный'),
       ('W2', 'Северный'),
       ('W3', 'Южный'),
       ('W4', 'Западный'),
       ('W5', 'Восточный');

INSERT INTO lab.inventory (warehouse_code, product_id, quantity)
SELECT 'W1', product_id, 20
FROM olist.products
ORDER BY product_id
LIMIT 5;

INSERT INTO lab.transfers (transfer_id, source_code, destination_code)
VALUES (1, 'W1', 'W2'),
       (2, 'W1', 'W3'),
       (3, 'W1', 'W4'),
       (4, 'W1', 'W5'),
       (5, 'W1', 'W2');

INSERT INTO lab.transfer_items (transfer_id, product_id, quantity)
SELECT t.transfer_id, p.product_id, 2
FROM lab.transfers AS t
CROSS JOIN (
    SELECT product_id
    FROM lab.inventory
    WHERE warehouse_code = 'W1'
    ORDER BY product_id
    LIMIT 1
) AS p
WHERE t.transfer_id BETWEEN 1 AND 5;

--Ошибочные операции
--UNIQUE: склад с названием «Центральный» уже существует.
INSERT INTO lab.warehouses (warehouse_code, warehouse_name)
VALUES ('W6', 'Центральный');

--CHECK: склад-отправитель и склад-получатель должны различаться.
INSERT INTO lab.transfers (transfer_id, source_code, destination_code)
VALUES (6, 'W1', 'W1');

--FOREIGN KEY: склада W999 нет в таблице warehouses.
INSERT INTO lab.transfers (transfer_id, source_code, destination_code)
VALUES (7, 'W1', 'W999');

--Проверка схемы
SELECT table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'lab'
  AND table_name IN ('warehouses', 'inventory', 'transfers', 'transfer_items')
ORDER BY table_name, constraint_type, constraint_name;