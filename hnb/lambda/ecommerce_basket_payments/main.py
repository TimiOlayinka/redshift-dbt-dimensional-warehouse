import json
import boto3
import uuid
import os
import gzip
from datetime import datetime
import random

s3 = boto3.client('s3')

def generate_basket_payments(num_records=100):
    records = []
    for _ in range(num_records):
        payment_method_id = random.randint(1, 5) # 1: CC, 2: PayPal, 3: Apple, 4: Google, 5: Klarna
        record = {
            "payment_id": str(uuid.uuid4()),
            "basket_id": f"BSK-{random.randint(100000, 999999)}",
            "customer_id": f"CUST-{random.randint(10000, 99999)}",
            "payment_method_id": payment_method_id,
            "amount": round(random.uniform(20.0, 500.0), 2),
            "currency": "GBP",
            "payment_status": random.choice(["Success", "Success", "Success", "Failed", "Pending"]),
            "processed_at": datetime.utcnow().isoformat(),
            "brand": random.choice(["HNB", "PrettyLittleThing", "NastyGal", "Karen Millen", "Coast", "Debenhams"])
        }
        records.append(record)
    return records

def lambda_handler(event, context):
    bucket = os.environ.get('S3_BUCKET', 'hnb-data-lake')
    prefix = 'hnb/ecommerce/basket_payments/history/ingest_date=' + datetime.utcnow().strftime('%Y-%m-%d')
    
    records = generate_basket_payments(random.randint(500, 2000))
    jsonl = '\n'.join([json.dumps(r) for r in records]).encode('utf-8')
    compressed = gzip.compress(jsonl)
    
    key = f"{prefix}/basket_payments.jsonl.gz"
    
    # s3.put_object(Bucket=bucket, Key=key, Body=compressed)
    
    print(f"Generated {len(records)} basket payments records for {key}")
    return {
        "statusCode": 200,
        "body": f"Successfully processed {len(records)} records."
    }
