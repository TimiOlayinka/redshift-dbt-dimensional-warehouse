{{
    config(
        materialized='incremental',
        unique_key='basket_item_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='basket_id',
        sort=['added_at', 'brand', 'category_id'],
        tags=['odl', 'ecommerce', 'fact']
    )
}}

WITH stg_items AS (
    SELECT
        basket_item_id,
        basket_id,
        product_id,
        category_id,
        quantity,
        unit_price,
        total_price,
        added_at,
        brand
    FROM {{ ref('stg_basket_items') }}
    {% if is_incremental() %}
    WHERE added_at >= (
        SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(added_at), '1970-01-01'::TIMESTAMP))
        FROM {{ this }}
    )
    {% endif %}
)

SELECT
    MD5(i.basket_item_id) AS basket_item_sk,
    i.basket_item_id,
    i.basket_id,
    i.product_id,
    i.category_id,
    c.category_name,
    c.department,
    c.parent_category_name,
    c.margin_tier,
    i.quantity,
    i.unit_price,
    i.total_price,
    i.added_at,
    i.brand,
    -- Lineage metadata
    'stg_basket_items' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM stg_items AS i
LEFT JOIN {{ ref('dim_product_category') }} AS c
    ON i.category_id = c.category_id
