Бизнес-правило	и Ограничение
У каждого склада уникальный код	pk_warehouses
Названия складов обязательны и уникальны	NOT NULL, uq_warehouses_name
Для пары «склад, товар» хранится один остаток	pk_inventory
Остаток товара не может быть отрицательным	ck_inventory_quantity
Отправителем и получателем могут быть только существующие склады	fk_transfers_source, fk_transfers_destination
Склады отправления и назначения должны различаться	ck_transfers_different_warehouses
Товар может встретиться в перемещении один раз, с положительным количеством	pk_transfer_items, ck_transfer_items_quantity
В остатках и перемещениях используются существующие товары Olist	fk_inventory_product, fk_transfer_items_product