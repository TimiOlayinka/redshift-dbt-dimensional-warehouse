{{ config(materialized='view') }}

WITH raw AS (
    SELECT * FROM {{ source('cx_raw', 'rdl_smg_nps_visitview') }}
)
SELECT 
    JSON_EXTRACT_PATH_TEXT(raw_data, 'survey_id') AS survey_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'session_id') AS session_id,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'visitor_id') AS visitor_id,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'response_date') AS TIMESTAMP) AS response_date,
    CAST(JSON_EXTRACT_PATH_TEXT(raw_data, 'nps_score') AS INT) AS nps_score,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'comment') AS nps_comment,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'device_category') AS device_category,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'page_url') AS page_url,
    JSON_EXTRACT_PATH_TEXT(raw_data, 'brand') AS brand
FROM raw
