{{ config(materialized='view') }}

WITH raw AS (
    SELECT * FROM {{ source('ecommerce_raw', 'rdl_basket_items') }}
)
SELECT 
    JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_item_id') AS basket_item_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_id') AS basket_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'product_id') AS product_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'category_id') AS INT) AS category_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'quantity') AS INT) AS quantity,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'unit_price') AS NUMERIC(10,2)) AS unit_price,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'total_price') AS NUMERIC(10,2)) AS total_price,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'added_at') AS TIMESTAMP) AS added_at,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'brand') AS brand
FROM raw
