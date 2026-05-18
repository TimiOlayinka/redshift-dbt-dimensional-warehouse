{{ config(materialized='table') }}

{% set categories = var('dim_product_category') %}

{% for c in categories %}
  SELECT 
    {{ c.category_id }} AS category_id,
    '{{ c.category_name }}' AS category_name,
    {% if c.parent_id is none %} NULL {% else %} {{ c.parent_id }} {% endif %} AS parent_category_id,
    -- Lineage metadata
    'YAML mapping' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
  {% if not loop.last %} UNION ALL {% endif %}
{% endfor %}
