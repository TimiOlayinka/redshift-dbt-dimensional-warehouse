"""Airflow DAG 01_ecommerce_ingestion: Invokes AWS Lambda E-Commerce Basket Items & Payments generators."""

from __future__ import annotations

from datetime import datetime, timedelta
import json

from airflow import DAG
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

ECOMMERCE_LAMBDA_FUNCTIONS = [
    ("invoke_basket_items", "ecommerce_basket_items"),
    ("invoke_basket_payments", "ecommerce_basket_payments"),
]

with DAG(
    dag_id="01_ecommerce_ingestion",
    default_args=default_args,
    description="Invoke AWS Lambda generators for Vitality E-Commerce Basket Items and Payments into S3",
    schedule="0 1 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["ecommerce", "ingestion", "lambda", "s3"],
) as dag:

    with TaskGroup(group_id="ecommerce_lambda_generators") as ecommerce_generators:
        for task_id, fn_name in ECOMMERCE_LAMBDA_FUNCTIONS:
            LambdaInvokeFunctionOperator(
                task_id=task_id,
                function_name=fn_name,
                aws_conn_id="aws_default",
                invocation_type="RequestResponse",
                payload=json.dumps({"ingest_date": "{{ ds }}", "dry_run": False}),
            )
