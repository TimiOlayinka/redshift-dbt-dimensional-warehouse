{% macro clean_string(column_expr) -%}
    NULLIF(TRIM({{ column_expr }}), '')
{%- endmacro %}

{% macro normalize_brand(column_expr) -%}
    CASE
        WHEN UPPER(TRIM({{ column_expr }})) IN ('VITALITY', 'VRG', 'VITALITY RETAIL', 'VITALITY RETAIL GROUP')
            THEN 'Vitality Retail'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('VITALITY INTERNATIONAL', 'VRG INTERNATIONAL', 'INTERNATIONAL')
            THEN 'Vitality International'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('PUREBOTANICS', 'PURE BOTANICS', 'PUREBOTANICS CBD')
            THEN 'PureBotanics'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('NUTRICORE', 'NUTRICORE PARTNER')
            THEN 'NutriCore Partner'
        WHEN UPPER(TRIM({{ column_expr }})) IN ('AROMAVITA', 'AROMA VITA')
            THEN 'AromaVita'
        ELSE COALESCE(NULLIF(TRIM({{ column_expr }}), ''), 'Vitality Retail')
    END
{%- endmacro %}

{% macro hash_pii(column_expr) -%}
    SHA2(LOWER(TRIM(COALESCE({{ column_expr }}, ''))), 256)
{%- endmacro %}
