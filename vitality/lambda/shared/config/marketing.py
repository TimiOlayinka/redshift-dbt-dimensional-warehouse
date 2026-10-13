"""Customer Experience (CX) & Digital Marketing configuration for NPS & Support generators."""

from __future__ import annotations

from typing import Final

SURVEY_PLATFORMS: Final[list[str]] = ["Web", "App"]
SURVEY_PLATFORM_WEIGHTS: Final[list[float]] = [0.62, 0.38]

DEVICE_CATEGORIES: Final[list[str]] = ["Mobile", "Desktop", "Tablet"]
DEVICE_CATEGORY_WEIGHTS: Final[list[float]] = [0.64, 0.30, 0.06]

VITALITY_PAGE_URLS: Final[list[str]] = [
    "/home",
    "/checkout",
    "/vitamins-supplements/multivitamins",
    "/sports-nutrition/whey-plant-protein",
    "/gut-health-probiotics/live-bacteria",
    "/natural-beauty/clean-skincare",
    "/food-drink/kombucha-functional-teas",
    "/rewards-for-life",
]

SUPPORT_CHANNELS: Final[list[str]] = ["Email", "Chat", "Phone", "Social Media"]
SUPPORT_CHANNEL_WEIGHTS: Final[list[float]] = [0.35, 0.40, 0.15, 0.10]

SUPPORT_TICKET_STATUSES: Final[list[str]] = ["Closed", "Resolved", "Open", "Pending"]
SUPPORT_TICKET_STATUS_WEIGHTS: Final[list[float]] = [0.48, 0.34, 0.10, 0.08]

SUPPORT_CONTACT_REASONS: Final[list[str]] = [
    "Where is my order?",
    "Subscription Delivery Delay",
    "Returns",
    "Defective Item",
    "Rewards Points Balance",
    "Adverse Reaction / Allergy Query",
    "Account Issue",
]

POSTSHIP_COMMENTS_BY_BAND: Final[dict[str, list[str]]] = {
    "Promoter": [
        "Fast next-day delivery and eco-friendly packaging.",
        "Great Subscribe & Save discount on my daily probiotics.",
        "Always reliable quality for vitamins and supplements.",
    ],
    "Passive": [
        "Product is good but courier left parcel on doorstep.",
        "Decent range, though one item was out of stock.",
    ],
    "Detractor": [
        "Next-day delivery arrived 4 days late with crushed box.",
        "Missing item from my wellness subscription order.",
        "Seal on protein tub was damaged in transit.",
    ],
}

VISITVIEW_COMMENTS_BY_BAND: Final[dict[str, list[str]]] = {
    "Promoter": [
        "Easy to filter supplements by vegan and gluten-free.",
        "Rewards for Life voucher applied seamlessly at checkout.",
    ],
    "Passive": [
        "Found what I wanted eventually, search bar could be faster.",
        "Okay mobile browsing experience.",
    ],
    "Detractor": [
        "Checkout page froze when applying Klarna payment.",
        "Site is slow on mobile when viewing product ingredients.",
    ],
}
