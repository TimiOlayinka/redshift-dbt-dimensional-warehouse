{{ config(materialized='view') }}

WITH raw AS (
    SELECT * FROM {{ source('cx_raw', 'rdl_smg_nps_postship') }}
)
SELECT 
    JSON_EXTRACT_PATH_TEXT(raw_data, 'survey_id') AS survey_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'customer_id') AS customer_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'order_id') AS order_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'response_date') AS TIMESTAMP) AS response_date,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'nps_score') AS INT) AS nps_score,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'comment') AS nps_comment,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'platform') AS platform,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'brand') AS brand
FROM raw
