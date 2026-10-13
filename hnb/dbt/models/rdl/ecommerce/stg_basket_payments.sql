{{
    config(
        materialized='view',
        tags=['rdl', 'ecommerce', 'staging']
    )
}}

WITH raw_source AS (
    SELECT
        raw_data
    FROM {{ source('ecommerce_raw', 'rdl_basket_payments') }}
    WHERE raw_data IS NOT NULL
),

extracted AS (
    SELECT
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_id')") }} AS payment_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'basket_id')") }} AS basket_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_id,
        {{ hash_pii("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_pii_hash,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_method_id')), '') AS INT) AS payment_method_id,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'amount')), '') AS NUMERIC(10, 2)) AS amount,
        UPPER(COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'currency')") }}, 'GBP')) AS currency,
        INITCAP(COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'payment_status')") }}, 'Pending')) AS payment_status,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'processed_at')), '') AS TIMESTAMP) AS processed_at,
        {{ normalize_brand("JSON_EXTRACT_PATH_TEXT(raw_data, 'brand')") }} AS brand
    FROM raw_source
)

SELECT
    payment_id,
    basket_id,
    customer_id,
    customer_pii_hash,
    payment_method_id,
    amount,
    currency,
    payment_status,
    processed_at,
    brand
FROM extracted
WHERE
    payment_id IS NOT NULL
    AND basket_id IS NOT NULL
    AND amount > 0
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY payment_id
    ORDER BY processed_at DESC
) = 1
