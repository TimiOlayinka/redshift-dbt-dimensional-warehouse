{{ config(materialized='table') }}

SELECT
    payment_id,
    basket_id,
    customer_id,
    payment_method_id,
    amount,
    currency,
    payment_status,
    processed_at,
    brand,
    -- Lineage metadata
    'stg_basket_payments' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_basket_payments') }}
