"""Core configuration constants shared across all H&B AWS Lambda ingestion functions."""

from __future__ import annotations

import os
from typing import Final

DEFAULT_AWS_REGION: Final[str] = os.environ.get("AWS_REGION", "eu-west-2")
DEFAULT_S3_BUCKET: Final[str] = os.environ.get("S3_BUCKET", "hnb-data-lake")
S3_KEY_PREFIX_ROOT: Final[str] = "hnb"

# Canonical Health & Wellness retail brands in the H&B Group portfolio
HNB_BRANDS: Final[list[str]] = [
    "Holland & Barrett",
    "H&B International",
    "Pureis",
    "Vitabiotics Partner",
    "Miaroma",
]

# Realistic commercial traffic weights per brand
HNB_BRAND_WEIGHTS: Final[list[float]] = [0.58, 0.16, 0.10, 0.09, 0.07]

# S3 upload resilience settings
S3_MAX_RETRIES: Final[int] = 3
S3_BASE_BACKOFF_SECONDS: Final[float] = 0.5
