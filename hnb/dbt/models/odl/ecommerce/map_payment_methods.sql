{{ config(materialized='table') }}

{% set payment_methods = var('map_payment_methods') %}

{% for p in payment_methods %}
  SELECT 
    {{ p.id }} AS payment_method_id,
    '{{ p.method }}' AS payment_method_name,
    {{ p.fee_percentage }} AS fee_percentage,
    -- Lineage metadata
    'YAML mapping' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
  {% if not loop.last %} UNION ALL {% endif %}
{% endfor %}
