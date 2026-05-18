{{ config(materialized='table') }}

SELECT
    survey_id,
    customer_id,
    order_id,
    response_date,
    nps_score,
    nps_comment,
    platform,
    brand,
    CASE 
        WHEN nps_score >= 9 THEN 'Promoter'
        WHEN nps_score >= 7 THEN 'Passive'
        ELSE 'Detractor'
    END AS nps_category
FROM {{ ref('stg_smg_nps_postship') }}
