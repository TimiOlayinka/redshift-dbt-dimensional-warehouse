{{
    config(
        materialized='table',
        dist='customer_id',
        sort=['brand', 'status', 'created_at'],
        tags=['odl', 'cx', 'dimension']
    )
}}

SELECT
    MD5(ticket_id) AS ticket_sk,
    ticket_id,
    customer_id,
    customer_pii_hash,
    created_at,
    resolved_at,
    status,
    channel,
    reason,
    brand,
    CASE
        WHEN reason IN ('Defective Item', 'Adverse Reaction / Allergy Query', 'Missing Prescription / Cold Chain')
            THEN 'P1 - High Priority'
        WHEN reason IN ('Where is my order?', 'Subscription Delivery Delay', 'Refund Not Received')
            THEN 'P2 - Medium Priority'
        ELSE 'P3 - Standard'
    END AS priority_tier,
    CASE
        WHEN status IN ('Resolved', 'Closed') THEN TRUE
        ELSE FALSE
    END AS is_resolved,
    -- Lineage metadata
    'stg_cx_tickets' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_cx_tickets') }}
