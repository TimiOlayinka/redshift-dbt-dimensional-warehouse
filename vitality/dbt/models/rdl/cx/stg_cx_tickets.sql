{{
    config(
        materialized='view',
        tags=['rdl', 'cx', 'staging']
    )
}}

WITH raw_source AS (
    SELECT
        raw_data
    FROM {{ source('cx_raw', 'rdl_cx_tickets') }}
    WHERE raw_data IS NOT NULL
),

extracted AS (
    SELECT
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'ticket_id')") }} AS ticket_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_id,
        {{ hash_pii("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_pii_hash,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'created_at')), '') AS TIMESTAMP) AS created_at,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'resolved_at')), '') AS TIMESTAMP) AS resolved_at,
        INITCAP( COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'status')") }}, 'Open') ) AS status,
        COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'channel')") }}, 'Web') AS channel,
        COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'reason')") }}, 'General Enquiry') AS reason,
        CASE
            WHEN CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'csat_score')), '') AS INT) BETWEEN 1 AND 5
                THEN CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'csat_score')), '') AS INT)
            ELSE NULL
        END AS csat_score,
        {{ normalize_brand("JSON_EXTRACT_PATH_TEXT(raw_data, 'brand')") }} AS brand
    FROM raw_source
)

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
FROM extracted
WHERE
    ticket_id IS NOT NULL
    AND customer_id IS NOT NULL
    AND created_at IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ticket_id
    ORDER BY COALESCE(resolved_at, created_at) DESC
) = 1
