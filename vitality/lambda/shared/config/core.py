"""Core configuration constants shared across all Vitality AWS Lambda ingestion functions."""

from __future__ import annotations

import os
from typing import Final

DEFAULT_AWS_REGION: Final[str] = os.environ.get("AWS_REGION", "eu-west-2")
DEFAULT_S3_BUCKET: Final[str] = os.environ.get("S3_BUCKET", "vitality-data-lake")
S3_KEY_PREFIX_ROOT: Final[str] = "vitality"

# Canonical Health & Wellness retail brands in the Vitality Retail Group portfolio
VITALITY_BRANDS: Final[list[str]] = [
    "Vitality Retail",
    "Vitality International",
    "PureBotanics",
    "NutriCore Partner",
    "AromaVita",
]

# Realistic commercial traffic weights per brand
VITALITY_BRAND_WEIGHTS: Final[list[float]] = [0.58, 0.16, 0.10, 0.09, 0.07]

# S3 upload resilience settings
S3_MAX_RETRIES: Final[int] = 3
S3_BASE_BACKOFF_SECONDS: Final[float] = 0.5
