"""Airflow DAG 02_transform_cx: Consolidated end-to-end dbt pipeline orchestrator (RDL -> Snapshots -> ODL -> ADL)."""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

DBT_PROJECT_DIR = "/opt/airflow/dbt/vitality"

default_args = {
    "owner": "vitality-analytics-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
}

with DAG(
    dag_id="02_transform_cx",
    default_args=default_args,
    description="End-to-end dbt Core transformation pipeline for Vitality CX & E-Commerce (RDL -> ODL -> ADL)",
    schedule="0 2 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["cx", "ecommerce", "dbt", "transformation"],
) as dag:

    dbt_deps_and_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt deps && dbt source freshness --target prod",
    )

    with TaskGroup(group_id="rdl_staging") as rdl_group:
        dbt_run_rdl = BashOperator(
            task_id="dbt_run_rdl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select path:models/rdl --target prod",
        )
        dbt_test_rdl = BashOperator(
            task_id="dbt_test_rdl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/rdl --target prod",
        )
        dbt_run_rdl >> dbt_test_rdl

    with TaskGroup(group_id="odl_kimball") as odl_group:
        dbt_snapshot = BashOperator(
            task_id="dbt_snapshot_scd2",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt snapshot --target prod",
        )
        dbt_run_odl = BashOperator(
            task_id="dbt_run_odl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select path:models/odl --target prod",
        )
        dbt_test_odl = BashOperator(
            task_id="dbt_test_odl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/odl --target prod",
        )
        dbt_snapshot >> dbt_run_odl >> dbt_test_odl

    with TaskGroup(group_id="adl_executive_marts") as adl_group:
        dbt_run_adl = BashOperator(
            task_id="dbt_run_adl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select path:models/adl --target prod",
        )
        dbt_test_adl = BashOperator(
            task_id="dbt_test_adl",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/adl --target prod",
        )
        dbt_run_adl >> dbt_test_adl

    dbt_deps_and_freshness >> rdl_group >> odl_group >> adl_group
