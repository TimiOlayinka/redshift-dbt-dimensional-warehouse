import json
import boto3
import uuid
import os
import gzip
from datetime import datetime
import random

s3 = boto3.client('s3')

def generate_visitview_nps(num_records=100):
    records = []
    for _ in range(num_records):
        score = random.choices([random.randint(0,6), random.randint(7,8), random.randint(9,10)], weights=[0.20, 0.30, 0.50])[0]
        record = {
            "survey_id": str(uuid.uuid4()),
            "session_id": f"SESS-{random.randint(1000000, 9999999)}",
            "visitor_id": f"VIS-{random.randint(1000, 9999)}",
            "response_date": datetime.utcnow().isoformat(),
            "nps_score": score,
            "comment": "Site is slow" if score < 6 else "Easy to find what I wanted" if score > 8 else "Okay experience",
            "device_category": random.choice(["Mobile", "Desktop", "Tablet"]),
            "page_url": random.choice(["/home", "/checkout", "/product/123", "/category/shoes"]),
            "brand": random.choice(["HNB", "Karen Millen", "Debenhams"])
        }
        records.append(record)
    return records

def lambda_handler(event, context):
    bucket = os.environ.get('S3_BUCKET', 'hnb-data-lake')
    prefix = 'hnb/cx/nps_visitview/history/ingest_date=' + datetime.utcnow().strftime('%Y-%m-%d')
    
    records = generate_visitview_nps(random.randint(1000, 5000))
    jsonl = '\n'.join([json.dumps(r) for r in records]).encode('utf-8')
    compressed = gzip.compress(jsonl)
    
    key = f"{prefix}/nps_visitview.jsonl.gz"
    
    # s3.put_object(Bucket=bucket, Key=key, Body=compressed)
    
    print(f"Generated {len(records)} visitview NPS records for {key}")
    return {
        "statusCode": 200,
        "body": f"Successfully processed {len(records)} records."
    }
