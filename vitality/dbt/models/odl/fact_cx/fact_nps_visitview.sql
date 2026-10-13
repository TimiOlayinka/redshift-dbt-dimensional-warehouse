{{
    config(
        materialized='incremental',
        unique_key='survey_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='visitor_id',
        sort=['response_date', 'brand'],
        tags=['odl', 'cx', 'fact']
    )
}}

SELECT
    MD5('visitview|' || survey_id) AS survey_sk,
    survey_id,
    session_id,
    visitor_id,
    visitor_pii_hash,
    response_date,
    nps_score,
    nps_comment,
    device_category,
    page_url,
    brand,
    {{ calculate_nps_category('nps_score') }} AS nps_category,
    -- Lineage metadata
    'stg_smg_nps_visitview' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_smg_nps_visitview') }}
{% if is_incremental() %}
WHERE response_date >= (
    SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(response_date), '1970-01-01'::TIMESTAMP))
    FROM {{ this }}
)
{% endif %}
