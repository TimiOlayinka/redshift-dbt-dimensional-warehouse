{{
    config(
        materialized='incremental',
        unique_key='survey_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        dist='customer_id',
        sort=['response_date', 'brand'],
        tags=['odl', 'cx', 'fact']
    )
}}

SELECT
    MD5('postship|' || survey_id) AS survey_sk,
    survey_id,
    customer_id,
    customer_pii_hash,
    order_id,
    response_date,
    nps_score,
    nps_comment,
    platform,
    brand,
    {{ calculate_nps_category('nps_score') }} AS nps_category,
    -- Lineage metadata
    'stg_smg_nps_postship' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM {{ ref('stg_smg_nps_postship') }}
{% if is_incremental() %}
WHERE response_date >= (
    SELECT DATEADD(day, -{{ var('incremental_lookback_days', 3) }}, COALESCE(MAX(response_date), '1970-01-01'::TIMESTAMP))
    FROM {{ this }}
)
{% endif %}
