{{
    config(
        materialized='incremental',
        unique_key='survey_sk',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='customer_id',
        sort=['response_date', 'brand', 'survey_type'],
        tags=['odl', 'cx', 'fact']
    )
}}

WITH postship_surveys AS (
    SELECT
        survey_id,
        'postship' AS survey_type,
        customer_id,
        customer_pii_hash,
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
        'stg_smg_nps_postship' AS _source_table
    FROM {{ ref('stg_smg_nps_postship') }}
    {% if is_incremental() %}
    WHERE response_date >= (
        SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(response_date), '1970-01-01'::TIMESTAMP))
        FROM {{ this }}
    )
    {% endif %}
),

visitview_surveys AS (
    SELECT
        survey_id,
        'visitview' AS survey_type,
        COALESCE(visitor_id, 'ANON-' || session_id) AS customer_id,
        visitor_pii_hash AS customer_pii_hash,
        CAST(NULL AS VARCHAR) AS order_id,
        session_id,
        visitor_id,
        response_date,
        nps_score,
        nps_comment,
        CASE
            WHEN device_category = 'Mobile' THEN 'App'
            ELSE 'Web'
        END AS platform,
        device_category,
        page_url,
        brand,
        'stg_smg_nps_visitview' AS _source_table
    FROM {{ ref('stg_smg_nps_visitview') }}
    {% if is_incremental() %}
    WHERE response_date >= (
        SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(response_date), '1970-01-01'::TIMESTAMP))
        FROM {{ this }}
    )
    {% endif %}
),

unified_surveys AS (
    SELECT * FROM postship_surveys
    UNION ALL
    SELECT * FROM visitview_surveys
)

SELECT
    MD5(u.survey_type || '|' || u.survey_id) AS survey_sk,
    u.survey_id,
    u.survey_type,
    u.customer_id,
    u.customer_pii_hash,
    u.order_id,
    u.session_id,
    u.visitor_id,
    u.response_date,
    u.nps_score,
    u.nps_comment,
    u.platform,
    p.platform_id,
    p.channel_group,
    u.device_category,
    u.page_url,
    u.brand,
    {{ calculate_nps_category('u.nps_score') }} AS nps_category,
    -- Lineage metadata
    u._source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM unified_surveys AS u
LEFT JOIN {{ ref('dim_feedback_platforms') }} AS p
    ON u.platform = p.platform_code
