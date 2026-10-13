{% macro clean_string(column_expr) -%}
    NULLIF(TRIM({{ column_expr }}), '')
{%- endmacro %}

{% macro normalize_brand(column_expr) -%}
    CASE
        WHEN UPPER(TRIM({{ column_expr }})) IN ('HNB', 'H&B', 'HOLLAND & BARRETT', 'HOLLAND AND BARRETT')
            THEN 'Holland & Barrett'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('H&B INTERNATIONAL', 'HNB INTERNATIONAL', 'INTERNATIONAL')
            THEN 'H&B International'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('PUREIS', 'PUREIS CBD')
            THEN 'Pureis'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('VITABIOTICS', 'VITABIOTICS PARTNER')
            THEN 'Vitabiotics Partner'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('MIAROMA', 'MIA ROMA')
            THEN 'Miaroma'
        ELSE COALESCE(NULLIF(TRIM({{ column_expr }}), ''), 'Holland & Barrett')
    END
{%- endmacro %}

{% macro hash_pii(column_expr) -%}
    SHA2(LOWER(TRIM(COALESCE({{ column_expr }}, ''))), 256)
{%- endmacro %}
