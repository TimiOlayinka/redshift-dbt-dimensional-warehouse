{{ config(materialized='view') }}

WITH raw AS (
    SELECT * FROM {{ source('cx_raw', 'rdl_cx_tickets') }}
)
SELECT 
    JSON_EXTRACT_PATH_TEXT(raw_data, 'ticket_id') AS ticket_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id') AS customer_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'created_at') AS TIMESTAMP) AS created_at,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'resolved_at') AS TIMESTAMP) AS resolved_at,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'status') AS status,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'channel') AS channel,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'reason') AS reason,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'csat_score') AS INT) AS csat_score,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'brand') AS brand
FROM raw
