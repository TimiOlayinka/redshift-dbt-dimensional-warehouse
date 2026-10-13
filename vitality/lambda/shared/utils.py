"""Shared utility functions for JSONL compression, S3 partition path routing, and resilient uploads."""

from __future__ import annotations

import gzip
import json
import logging
import time
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from shared.config.core import (
    DEFAULT_AWS_REGION,
    S3_BASE_BACKOFF_SECONDS,
    S3_KEY_PREFIX_ROOT,
    S3_MAX_RETRIES,
)


def setup_logger(name: str) -> logging.Logger:
    """Configure and return a structured logger for AWS Lambda CloudWatch output."""
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            fmt="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
            datefmt="%Y-%m-%dT%H:%M:%SZ",
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger


def build_s3_partition_key(domain: str, dataset: str, ingest_date: str | None = None) -> str:
    """Construct the canonical Hive-partitioned S3 object key.

    Pattern: `vitality/{domain}/{dataset}/history/ingest_date={yyyy-mm-dd}/{dataset}.jsonl.gz`
    """
    partition_date = ingest_date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return f"{S3_KEY_PREFIX_ROOT}/{domain}/{dataset}/history/ingest_date={partition_date}/{dataset}.jsonl.gz"


def serialize_and_compress_jsonl(records: list[dict[str, Any]]) -> bytes:
    """Serialize a list of dictionaries to UTF-8 JSON Lines and compress with GZIP."""
    jsonl_payload = "\n".join(json.dumps(record, separators=(",", ":")) for record in records).encode("utf-8")
    return gzip.compress(jsonl_payload, compresslevel=6)


def upload_to_s3_with_backoff(
    bucket: str,
    key: str,
    payload_bytes: bytes,
    dry_run: bool = False,
    max_retries: int = S3_MAX_RETRIES,
) -> bool:
    """Upload compressed JSONL bytes to S3 with exponential backoff retry logic."""
    logger = setup_logger("vitality.s3_uploader")
    if dry_run:
        logger.info("DRY_RUN enabled — skipping S3 put_object for s3://%s/%s (%d bytes)", bucket, key, len(payload_bytes))
        return True

    s3_client = boto3.client("s3", region_name=DEFAULT_AWS_REGION)
    for attempt in range(1, max_retries + 1):
        try:
            s3_client.put_object(
                Bucket=bucket,
                Key=key,
                Body=payload_bytes,
                ContentType="application/x-ndjson",
                ContentEncoding="gzip",
                ServerSideEncryption="AES256",
            )
            logger.info("Uploaded %d bytes to s3://%s/%s on attempt %d", len(payload_bytes), bucket, key, attempt)
            return True
        except (ClientError, BotoCoreError) as exc:
            if attempt == max_retries:
                logger.error("Exhausted %d retries uploading to s3://%s/%s: %s", max_retries, bucket, key, exc)
                raise
            sleep_seconds = S3_BASE_BACKOFF_SECONDS * (2 ** (attempt - 1))
            logger.warning(
                "S3 upload attempt %d/%d failed (%s). Retrying in %.2fs...",
                attempt,
                max_retries,
                exc,
                sleep_seconds,
            )
            time.sleep(sleep_seconds)
    return False
