import json
import boto3
import uuid
import os
import gzip
from datetime import datetime, timedelta
import random

s3 = boto3.client('s3')

def generate_postship_nps(num_records=100):
    records = []
    today = datetime.utcnow().date()
    for _ in range(num_records):
        score = random.choices([random.randint(0,6), random.randint(7,8), random.randint(9,10)], weights=[0.15, 0.25, 0.60])[0]
        record = {
            "survey_id": str(uuid.uuid4()),
            "customer_id": f"CUST-{random.randint(10000, 99999)}",
            "order_id": f"ORD-{random.randint(100000, 999999)}",
            "response_date": datetime.utcnow().isoformat(),
            "nps_score": score,
            "comment": "Great service" if score > 8 else "Average" if score > 6 else "Terrible delivery",
            "platform": random.choice(["Web", "App"]),
            "brand": random.choice(["HNB", "PrettyLittleThing", "NastyGal"])
        }
        records.append(record)
    return records

def lambda_handler(event, context):
    bucket = os.environ.get('S3_BUCKET', 'hnb-data-lake')
    prefix = 'hnb/cx/nps_postship/history/ingest_date=' + datetime.utcnow().strftime('%Y-%m-%d')
    
    records = generate_postship_nps(random.randint(500, 2000))
    jsonl = '\n'.join([json.dumps(r) for r in records]).encode('utf-8')
    compressed = gzip.compress(jsonl)
    
    key = f"{prefix}/nps_postship.jsonl.gz"
    
    # In a real environment, we'd uncomment this to actually write to S3:
    # s3.put_object(Bucket=bucket, Key=key, Body=compressed)
    
    print(f"Generated {len(records)} postship NPS records for {key}")
    return {
        "statusCode": 200,
        "body": f"Successfully processed {len(records)} records."
    }
