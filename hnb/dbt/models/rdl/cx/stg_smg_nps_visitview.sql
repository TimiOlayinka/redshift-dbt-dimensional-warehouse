{{
    config(
        materialized='view',
        tags=['rdl', 'cx', 'staging']
    )
}}

WITH raw_source AS (
    SELECT
        raw_data
    FROM {{ source('cx_raw', 'rdl_smg_nps_visitview') }}
    WHERE raw_data IS NOT NULL
),

extracted AS (
    SELECT
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'survey_id')") }} AS survey_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'session_id')") }} AS session_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'visitor_id')") }} AS visitor_id,
        {{ hash_pii("JSON_EXTRACT_PATH_TEXT(raw_data, 'visitor_id')") }} AS visitor_pii_hash,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'response_date')), '') AS TIMESTAMP) AS response_date,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'nps_score')), '') AS INT) AS nps_score,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'comment')") }} AS nps_comment,
        INITCAP(COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'device_category')") }}, 'Desktop')) AS device_category,
        LOWER(COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'page_url')") }}, '/home')) AS page_url,
        {{ normalize_brand("JSON_EXTRACT_PATH_TEXT(raw_data, 'brand')") }} AS brand
    FROM raw_source
)

SELECT
    survey_id,
    session_id,
    visitor_id,
    visitor_pii_hash,
    response_date,
    nps_score,
    nps_comment,
    device_category,
    page_url,
    brand
FROM extracted
WHERE
    survey_id IS NOT NULL
    AND response_date IS NOT NULL
    AND nps_score BETWEEN 0 AND 10
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY survey_id
    ORDER BY response_date DESC
) = 1
