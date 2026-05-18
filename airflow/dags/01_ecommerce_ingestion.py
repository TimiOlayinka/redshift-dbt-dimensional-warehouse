from airflow import DAG
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'hnb-data-engineering',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    '01_ecommerce_ingestion',
    default_args=default_args,
    description='Invoke Lambda functions to generate simulated E-commerce Basket data and push to S3',
    schedule_interval='0 1 * * *',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['ecommerce', 'ingestion', 'lambda'],
) as dag:

    invoke_basket_items = LambdaInvokeFunctionOperator(
        task_id='invoke_basket_items',
        function_name='ecommerce_basket_items',
        aws_conn_id='aws_default',
    )

    invoke_basket_payments = LambdaInvokeFunctionOperator(
        task_id='invoke_basket_payments',
        function_name='ecommerce_basket_payments',
        aws_conn_id='aws_default',
    )

    [invoke_basket_items, invoke_basket_payments]
