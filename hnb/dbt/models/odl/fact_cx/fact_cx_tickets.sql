{{ config(materialized='table') }}

SELECT
    ticket_id,
    customer_id,
    created_at,
    resolved_at,
    status,
    channel,
    reason,
    csat_score,
    brand,
    EXTRACT(EPOCH FROM (resolved_at - created_at))/3600.0 AS resolution_time_hours
FROM {{ ref('stg_cx_tickets') }}
