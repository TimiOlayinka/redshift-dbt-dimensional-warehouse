{% macro calculate_nps_category(score_column) -%}
    CASE
        WHEN {{ score_column }} BETWEEN 9 AND 10 THEN 'Promoter'
        WHEN {{ score_column }} BETWEEN 7 AND 8 THEN 'Passive'
        WHEN {{ score_column }} BETWEEN 0 AND 6 THEN 'Detractor'
        ELSE 'Invalid'
    END
{%- endmacro %}

{% macro calculate_net_nps_score(category_column) -%}
    ROUND(
        (
            SUM(CASE WHEN {{ category_column }} = 'Promoter' THEN 1.0 ELSE 0.0 END)
            - SUM(CASE WHEN {{ category_column }} = 'Detractor' THEN 1.0 ELSE 0.0 END)
        ) * 100.0 / NULLIF(COUNT({{ category_column }}), 0),
        2
    )
{%- endmacro %}
