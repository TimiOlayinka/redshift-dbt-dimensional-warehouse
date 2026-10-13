"""AWS Lambda generator for simulated SMG VisitView digital intercept NPS surveys."""

from __future__ import annotations

from datetime import datetime, timezone
import os
from pathlib import Path
import random
import sys
from typing import Any
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from shared.config.core import VITALITY_BRAND_WEIGHTS, VITALITY_BRANDS
from shared.config.marketing import (
    DEVICE_CATEGORIES,
    DEVICE_CATEGORY_WEIGHTS,
    VITALITY_PAGE_URLS,
    VISITVIEW_COMMENTS_BY_BAND,
)
from shared.handler_logic import execute_ingestion_pipeline


def generate_visitview_nps(num_records: int = 1000) -> list[dict[str, Any]]:
    """Generate realistic digital web & app browsing NPS survey payloads for Vitality Retail Group."""
    records: list[dict[str, Any]] = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for _ in range(num_records):
        band = random.choices(["Promoter", "Passive", "Detractor"], weights=[0.54, 0.28, 0.18], k=1)[0]
        if band == "Promoter":
            score = random.randint(9, 10)
        elif band == "Passive":
            score = random.randint(7, 8)
        else:
            score = random.randint(0, 6)

        records.append(
            {
                "survey_id": str(uuid.uuid4()),
                "session_id": f"SESS-{random.randint(1000000, 9999999)}",
                "visitor_id": f"VIS-{random.randint(10000, 99999)}",
                "response_date": now_iso,
                "nps_score": score,
                "comment": random.choice(VISITVIEW_COMMENTS_BY_BAND[band]),
                "device_category": random.choices(DEVICE_CATEGORIES, weights=DEVICE_CATEGORY_WEIGHTS, k=1)[0],
                "page_url": random.choice(VITALITY_PAGE_URLS),
                "brand": random.choices(VITALITY_BRANDS, weights=VITALITY_BRAND_WEIGHTS, k=1)[0],
            }
        )
    return records


def lambda_handler(event: dict[str, Any] | None = None, context: Any = None) -> dict[str, Any]:
    """AWS Lambda entrypoint for `cx_nps_visitview`."""
    return execute_ingestion_pipeline(
        domain="cx",
        dataset="nps_visitview",
        generator_fn=generate_visitview_nps,
        min_records=1000,
        max_records=4500,
        event=event,
    )


if __name__ == "__main__":
    os.environ.setdefault("DRY_RUN", "true")
    print(lambda_handler({"num_records": 10}))
