"""E-commerce domain configuration for H&B Basket Items & Payments generators."""

from __future__ import annotations

from typing import Final

# Leaf product category IDs aligned with dbt_project.yml `dim_product_category`
PRODUCT_CATEGORY_PRICE_RANGES: Final[dict[int, tuple[float, float]]] = {
    101: (8.99, 34.99),   # Multivitamins & Minerals
    102: (11.49, 42.00),  # Herbal & Botanical Extracts
    201: (19.99, 64.99),  # Whey & Plant Protein
    202: (14.99, 49.99),  # Creatine & Pre-Workout
    301: (12.00, 55.00),  # Clean Skincare & Serums
    302: (6.99, 28.00),   # Essential Oils & Aromatherapy
    401: (3.49, 18.99),   # Functional Teas & Kombucha
    402: (2.99, 22.50),   # Wholefoods & Healthy Snacks
    501: (16.99, 54.99),  # Live Friendly Bacteria (Probiotics)
    601: (14.49, 44.99),  # Meal Replacements & Fibres
}

LEAF_CATEGORY_IDS: Final[list[int]] = list(PRODUCT_CATEGORY_PRICE_RANGES.keys())

# Payment method IDs aligned with `map_payment_methods` in dbt_project.yml
# 1: Credit Card, 2: PayPal, 3: Apple Pay, 4: Google Pay, 5: Klarna, 6: H&B Rewards Points
PAYMENT_METHOD_IDS: Final[list[int]] = [1, 2, 3, 4, 5, 6]
PAYMENT_METHOD_WEIGHTS: Final[list[float]] = [0.38, 0.20, 0.18, 0.10, 0.08, 0.06]

PAYMENT_STATUSES: Final[list[str]] = ["Success", "Failed", "Pending", "Refunded"]
PAYMENT_STATUS_WEIGHTS: Final[list[float]] = [0.89, 0.05, 0.04, 0.02]

DEFAULT_CURRENCY: Final[str] = "GBP"
