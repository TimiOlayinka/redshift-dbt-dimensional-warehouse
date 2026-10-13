{{
    config(
        materialized='incremental',
        unique_key='payment_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='customer_id',
        sort=['processed_at', 'brand'],
        tags=['odl', 'ecommerce', 'fact']
    )
}}

WITH stg_payments AS (
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
    FROM {{ ref('stg_basket_payments') }}
    {% if is_incremental() %}
    WHERE processed_at >= (
        SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(processed_at), '1970-01-01'::TIMESTAMP))
        FROM {{ this }}
    )
    {% endif %}
)

SELECT
    MD5(p.payment_id) AS payment_sk,
    p.payment_id,
    p.basket_id,
    p.customer_id,
    p.customer_pii_hash,
    p.payment_method_id,
    m.payment_method_name,
    m.payment_provider,
    m.is_bnpl,
    p.amount AS gross_amount,
    ROUND(p.amount * (COALESCE(m.fee_percentage, 1.50) / 100.0), 2) AS gateway_fee_amount,
    ROUND(p.amount * (1.0 - COALESCE(m.fee_percentage, 1.50) / 100.0), 2) AS net_settlement_amount,
    p.currency,
    p.payment_status,
    p.processed_at,
    p.brand,
    -- Lineage metadata
    'stg_basket_payments' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM stg_payments AS p
LEFT JOIN {{ ref('map_payment_methods') }} AS m
    ON p.payment_method_id = m.payment_method_id
