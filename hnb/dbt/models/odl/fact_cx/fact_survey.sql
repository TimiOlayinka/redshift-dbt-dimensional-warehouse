{{ config(materialized='table') }}

WITH unified_surveys AS (
    SELECT
        survey_id,
        customer_id,
        order_id,
        CAST(NULL AS VARCHAR) AS session_id,
        CAST(NULL AS VARCHAR) AS visitor_id,
        response_date,
        nps_score,
        nps_comment,
        platform,
        CAST(NULL AS VARCHAR) AS device_category,
        CAST(NULL AS VARCHAR) AS page_url,
        brand,
        'postship' AS survey_type,
        -- Lineage
        'stg_smg_nps_postship' AS _source_table
    FROM {{ ref('stg_smg_nps_postship') }}

    UNION ALL

    SELECT
        survey_id,
        CAST(NULL AS VARCHAR) AS customer_id,
        CAST(NULL AS VARCHAR) AS order_id,
        session_id,
        visitor_id,
        response_date,
        nps_score,
        nps_comment,
        CAST(NULL AS VARCHAR) AS platform,
        device_category,
        page_url,
        brand,
        'visitview' AS survey_type,
        -- Lineage
        'stg_smg_nps_visitview' AS _source_table
    FROM {{ ref('stg_smg_nps_visitview') }}
)

SELECT
    survey_id,
    survey_type,
    customer_id,
    order_id,
    session_id,
    visitor_id,
    response_date,
    nps_score,
    nps_comment,
    platform,
    device_category,
    page_url,
    brand,
    CASE 
        WHEN nps_score >= 9 THEN 'Promoter'
        WHEN nps_score >= 7 THEN 'Passive'
        ELSE 'Detractor'
    END AS nps_category,
    -- Lineage metadata
    _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM unified_surveys
