{{
    config(
        materialized='table',
        dist='all',
        sort=['platform_code'],
        tags=['odl', 'cx', 'dimension']
    )
}}

{% set platforms = var('dim_feedback_platforms') %}

{% for p in platforms %}
SELECT
    MD5('{{ p.platform_code }}') AS platform_sk,
    '{{ p.platform_id }}' AS platform_id,
    '{{ p.platform_code }}' AS platform_code,
    '{{ p.channel_group }}' AS channel_group,
    '{{ p.vendor }}' AS vendor,
    '{{ p.survey_mechanism }}' AS survey_mechanism,
    -- Lineage metadata
    'dbt_project.yml vars' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
