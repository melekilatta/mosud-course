Реляционное выражение:
ρ(product_id, category, length, height, width)
  (π(product_id, product_category_name, product_length_cm,
     product_height_cm, product_width_cm)
    (σ(product_category_name IS NOT NULL
       ∧ product_length_cm × product_height_cm × product_width_cm > 20000)
      (products)))
Оба условия можно применить одним фильтром с AND или двумя последовательными выборками, поскольку в обоих случаях остаются строки, удовлетворяющие обоим условиям. Сравнение через EXCEPT в обе стороны показало, что состав результатов совпадает