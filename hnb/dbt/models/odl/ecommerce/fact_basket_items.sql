{{ config(materialized='table') }}

SELECT
    basket_item_id,
    basket_id,
    product_id,
    category_id,
    quantity,
    unit_price,
    total_price,
    added_at,
    brand,
    -- Lineage metadata
    'stg_basket_items' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_basket_items') }}
