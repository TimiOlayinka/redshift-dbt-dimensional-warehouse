{{ config(materialized='view') }}

WITH raw AS (
    SELECT * FROM {{ source('ecommerce_raw', 'rdl_basket_payments') }}
)
SELECT 
    JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_id') AS payment_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_id') AS basket_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id') AS customer_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_method_id') AS INT) AS payment_method_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'amount') AS NUMERIC(10,2)) AS amount,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'currency') AS currency,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_status') AS payment_status,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'processed_at') AS TIMESTAMP) AS processed_at,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'brand') AS brand
FROM raw
