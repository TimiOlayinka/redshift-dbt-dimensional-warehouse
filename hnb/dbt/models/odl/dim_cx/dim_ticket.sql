{{ config(materialized='table') }}

SELECT
    ticket_id,
    customer_id,
    created_at,
    status,
    channel,
    reason,
    brand,
    -- Lineage metadata
    'stg_cx_tickets' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_cx_tickets') }}
