{{
    config(
        materialized='view',
        tags=['rdl', 'ecommerce', 'staging']
    )
}}

WITH raw_source AS (
    SELECT
        raw_data
    FROM {{ source('ecommerce_raw', 'rdl_basket_items') }}
    WHERE raw_data IS NOT NULL
),

extracted AS (
    SELECT
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_item_id')") }} AS basket_item_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_id')") }} AS basket_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'product_id')") }} AS product_id,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'category_id')), '') AS INT) AS category_id,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'quantity')), '') AS INT) AS quantity,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'unit_price')), '') AS NUMERIC(10, 2)) AS unit_price,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'total_price')), '') AS NUMERIC(10, 2)) AS raw_total_price,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'added_at')), '') AS TIMESTAMP) AS added_at,
        {{ normalize_brand("JSON_EXTRACT_PATH_TEXT(raw_data, 'brand')") }} AS brand
    FROM raw_source
)

SELECT
    basket_item_id,
    basket_id,
    product_id,
    category_id,
    quantity,
    unit_price,
    COALESCE(raw_total_price, ROUND(quantity * unit_price, 2)) AS total_price,
    added_at,
    brand
FROM extracted
WHERE
    basket_item_id IS NOT NULL
    AND basket_id IS NOT NULL
    AND quantity > 0
    AND unit_price >= 0
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY basket_item_id
    ORDER BY added_at DESC
) = 1
