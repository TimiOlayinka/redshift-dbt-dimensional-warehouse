{{
    config(
        materialized='table',
        dist='all',
        sort=['category_id'],
        tags=['odl', 'ecommerce', 'dimension']
    )
}}

{% set categories = var('dim_product_category') %}

WITH raw_categories AS (
    {% for c in categories %}
    SELECT
        {{ c.category_id }} AS category_id,
        '{{ c.category_name }}' AS category_name,
        '{{ c.department }}' AS department,
        {% if c.parent_id is none %}CAST(NULL AS INT){% else %}{{ c.parent_id }}{% endif %} AS parent_category_id,
        '{{ c.margin_tier }}' AS margin_tier
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)

SELECT
    MD5(CAST(c.category_id AS VARCHAR)) AS category_sk,
    c.category_id,
    c.category_name,
    c.department,
    c.parent_category_id,
    COALESCE(p.category_name, c.category_name) AS parent_category_name,
    c.margin_tier,
    CASE
        WHEN c.parent_category_id IS NULL THEN 1
        ELSE 2
    END AS hierarchy_level,
    -- Lineage metadata
    'dbt_project.yml vars' AS _source_table,
    '{{ model.name }}' AS _dbt_model,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM raw_categories AS c
LEFT JOIN raw_categories AS p
    ON c.parent_category_id = p.category_id
