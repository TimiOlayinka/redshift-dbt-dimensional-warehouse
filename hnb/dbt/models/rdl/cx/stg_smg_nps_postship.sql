{{
    config(
        materialized='view',
        tags=['rdl', 'cx', 'staging']
    )
}}

WITH raw_source AS (
    SELECT
        raw_data
    FROM {{ source('cx_raw', 'rdl_smg_nps_postship') }}
    WHERE raw_data IS NOT NULL
),

extracted AS (
    SELECT
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'survey_id')") }} AS survey_id,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_id,
        {{ hash_pii("JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id')") }} AS customer_pii_hash,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'order_id')") }} AS order_id,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'response_date')), '') AS TIMESTAMP) AS response_date,
        CAST(NULLIF(TRIM(JSON_EXTRACT_PATH_TEXT(raw_data, 'nps_score')), '') AS INT) AS nps_score,
        {{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'comment')") }} AS nps_comment,
        COALESCE({{ clean_string("JSON_EXTRACT_PATH_TEXT(raw_data, 'platform')") }}, 'Web') AS platform,
        {{ normalize_brand("JSON_EXTRACT_PATH_TEXT(raw_data, 'brand')") }} AS brand
    FROM raw_source
)

SELECT
    survey_id,
    customer_id,
    customer_pii_hash,
    order_id,
    response_date,
    nps_score,
    nps_comment,
    platform,
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
