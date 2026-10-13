{{
    config(
        materialized='table',
        dist='all',
        sort=['payment_method_id'],
        tags=['odl', 'ecommerce', 'dimension']
    )
}}

{% set payment_methods = var('map_payment_methods') %}

{% for p in payment_methods %}
SELECT
    MD5(CAST({{ p.id }} AS VARCHAR)) AS payment_method_sk,
    {{ p.id }} AS payment_method_id,
    '{{ p.method }}' AS payment_method_name,
    '{{ p.provider }}' AS payment_provider,
    CAST({{ p.fee_percentage }} AS NUMERIC(5, 2)) AS fee_percentage,
    {% if p.is_bnpl %}TRUE{% else %}FALSE{% endif %} AS is_bnpl,
    -- Lineage metadata
    'dbt_project.yml vars' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
