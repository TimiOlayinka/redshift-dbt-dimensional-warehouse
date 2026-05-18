{{ config(materialized='table') }}

SELECT
    survey_id,
    session_id,
    visitor_id,
    response_date,
    nps_score,
    nps_comment,
    device_category,
    page_url,
    brand,
    CASE 
        WHEN nps_score >= 9 THEN 'Promoter'
        WHEN nps_score >= 7 THEN 'Passive'
        ELSE 'Detractor'
    END AS nps_category
FROM {{ ref('stg_smg_nps_visitview') }}
