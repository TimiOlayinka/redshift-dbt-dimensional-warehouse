{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}

    {%- if target.name == 'prod' -%}
        {# In production, route models directly to their canonical layer schema (rdl, odl, adl) #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- elif target.name == 'ci' -%}
        {# In Slim CI, isolate PR schemas (e.g., ci_pr_42_odl) to prevent collision and enable zero-copy teardown #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- else -%}
        {# In developer sandboxes, prefix with developer schema (e.g., dev_tolayinka_odl) #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
