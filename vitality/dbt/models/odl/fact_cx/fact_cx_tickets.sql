{{
    config(
        materialized='incremental',
        unique_key='ticket_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='customer_id',
        sort=['created_at', 'brand'],
        tags=['odl', 'cx', 'fact']
    )
}}

WITH stg_tickets AS (
    SELECT
        ticket_id,
        customer_id,
        customer_pii_hash,
        created_at,
        resolved_at,
        status,
        channel,
        reason,
        csat_score,
        brand
    FROM {{ ref('stg_cx_tickets') }}
    {% if is_incremental() %}
    WHERE COALESCE(resolved_at, created_at) >= (
        SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(created_at), '1970-01-01'::TIMESTAMP))
        FROM {{ this }}
    )
    {% endif %}
),

calculated AS (
    SELECT
        MD5(ticket_id) AS ticket_fact_sk,
        ticket_id,
        customer_id,
        customer_pii_hash,
        created_at,
        resolved_at,
        status,
        channel,
        reason,
        csat_score,
        brand,
        ROUND(
            CAST(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0 AS NUMERIC(10, 2)),
            2
        ) AS resolution_time_hours,
        CASE
            WHEN resolved_at IS NOT NULL
                AND EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0 <= {{ var('sla_first_response_hours', 4.0) }}
                THEN TRUE
            ELSE FALSE
        END AS is_first_contact_resolution,
        CASE
            WHEN resolved_at IS NOT NULL
                AND EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0 > {{ var('sla_resolution_hours', 24.0) }}
                THEN TRUE
            WHEN resolved_at IS NULL
                AND EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 3600.0 > {{ var('sla_resolution_hours', 24.0) }}
                THEN TRUE
            ELSE FALSE
        END AS is_sla_breached,
        CASE
            WHEN csat_score >= 4 THEN TRUE
            WHEN csat_score IS NOT NULL THEN FALSE
            ELSE NULL
        END AS is_positive_csat,
        -- Lineage metadata
        'stg_cx_tickets' AS _source_table,
        '{{ model.name }}' AS _dbt_model,
        CURRENT_TIMESTAMP AS _etl_loaded_at
    FROM stg_tickets
)

SELECT *
FROM calculated
