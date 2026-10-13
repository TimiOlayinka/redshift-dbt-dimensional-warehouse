"""Airflow DAG 01_cx_ingestion: Invokes AWS Lambda CX generators (Post-Ship NPS, VisitView NPS, Support Tickets)."""

from __future__ import annotations

from datetime import datetime, timedelta
import json

from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "vitality-analytics-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
    "retry_exponential_backoff": True,
    "execution_timeout": timedelta(minutes=10),
}

CX_LAMBDA_FUNCTIONS = [
    ("invoke_nps_postship", "cx_nps_postship"),
    ("invoke_nps_visitview", "cx_nps_visitview"),
    ("invoke_customer_support", "cx_customer_support"),
]

with DAG(
    dag_id="01_cx_ingestion",
    default_args=default_args,
    description="Invoke AWS Lambda generators for SMG NPS surveys & Zendesk support tickets into S3",
    schedule="0 1 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["cx", "ingestion", "lambda", "s3"],
) as dag:

    with TaskGroup(group_id="cx_lambda_generators") as cx_generators:
        for task_id, fn_name in CX_LAMBDA_FUNCTIONS:
            LambdaInvokeFunctionOperator(
                task_id=task_id,
                function_name=fn_name,
                aws_conn_id="aws_default",
                invocation_type="RequestResponse",
                payload=json.dumps({"ingest_date": "{{ ds }}", "dry_run": False}),
            )

    trigger_s3_to_redshift = TriggerDagRunOperator(
        task_id="trigger_01b_s3_to_redshift_ingestion",
        trigger_dag_id="01b_s3_to_redshift_ingestion",
        conf={"triggered_by": "01_cx_ingestion", "ingest_date": "{{ ds }}"},
        wait_for_completion=False,
    )

    cx_generators >> trigger_s3_to_redshift
