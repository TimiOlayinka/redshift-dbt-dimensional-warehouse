# HnB Project — Customer Experience (CX) Data Pipeline

End-to-end data platform built on AWS, orchestrating simulated Customer Experience (CX) data using Airflow, transformed with dbt, and visualised for executive reporting.

## Architecture Overview

This project simulates a production-grade Customer Experience data pipeline for HnB. It focuses specifically on the "CX" domain: ingesting SMG NPS (Net Promoter Score) surveys (post-purchase and website visits) alongside Customer Support tickets (Zendesk). 

The cloud environment is designed to be managed as Infrastructure as Code using Terraform, orchestrated by Apache Airflow, and follows a three-layer data warehouse pattern (RDL → ODL → ADL).

```mermaid
flowchart LR
    subgraph GENERATE["Data Generation"]
        L1["🔧 3 Lambda\nGenerators\n(NPS & Support)"]
    end
    
    subgraph ORCHESTRATE["Orchestration"]
        AF["🎯 Apache Airflow\nDAGs"]
    end
    
    subgraph STORE["Data Lake"]
        S3["📦 S3 Bucket\nJSONL.GZ\nCX Partitioned"]
    end
    
    subgraph WAREHOUSE["Data Warehouse"]
        RS["🏛️ Redshift\nServerless"]
    end
    
    subgraph TRANSFORM["Transformation"]
        DBT["⚙️ dbt Core\nCX Models"]
    end
    
    subgraph VISUALISE["Reporting"]
        LS["📊 BI Dashboard"]
    end

    AF -->|"Triggers"| L1
    L1 -->|"EventBridge\nDaily @ Midnight"| S3
    AF -->|"COPY"| RS
    S3 -->|"Ingestion"| RS
    RS -->|"RDL → ODL → ADL"| DBT
    AF -->|"Runs"| DBT
    DBT --> LS
    
    style GENERATE fill:#FF9900,color:#fff
    style ORCHESTRATE fill:#017CEE,color:#fff
    style STORE fill:#569A31,color:#fff
    style WAREHOUSE fill:#8C4FFF,color:#fff
    style TRANSFORM fill:#FF694B,color:#fff
    style VISUALISE fill:#4285F4,color:#fff
```

## Data Warehouse Layers

The warehouse follows the enterprise pattern, specifically modelling the CX domain:

```mermaid
flowchart TB
    subgraph RDL["RDL — Raw Data Layer"]
        direction LR
        R1["rdl_smg_nps_postship"]
        R2["rdl_smg_nps_visitview"]
        R3["rdl_cx_tickets"]
    end
    
    subgraph ODL["ODL — Operational Data Layer"]
        direction LR
        subgraph DIMS["Dimensions"]
            D2["dim_feedback_platforms"]
            D3["dim_ticket"]
        end
        subgraph FACTS["Facts"]
            F1["fact_survey"]
            F2["fact_cx_tickets"]
        end
    end
    
    subgraph ADL["ADL — Analytics Data Layer"]
        direction LR
        B2["bi_cx_executive_summary"]
    end

    RDL --> ODL
    ODL --> ADL

    style RDL fill:#1a1a2e,color:#e0e0e0,stroke:#FF9900
    style ODL fill:#1a1a2e,color:#e0e0e0,stroke:#8C4FFF
    style ADL fill:#1a1a2e,color:#e0e0e0,stroke:#4285F4
```

## S3 Data Lake Structure

```
hnb-data-lake/
├── hnb/
│   └── cx/
│       ├── nps_postship/
│       │   └── history/
│       │       └── ingest_date=2026-05-18/
│       │           └── nps_postship.jsonl.gz
│       ├── nps_visitview/
│       │   └── history/...
│       └── customer_support/
│           └── history/...
```

Path pattern: `hnb/cx/{dataset}/history/ingest_date={yyyy-mm-dd}/{dataset}.jsonl.gz`

## CX Analytics & BI
The ADL layer aggregates the NPS and Feedback data into BI-ready models:
- `bi_cx_executive_summary`: High-level aggregate view comparing CSAT (Customer Satisfaction) from support tickets vs NPS scores from web and post-purchase surveys.

## Airflow Orchestration

```mermaid
flowchart LR
    subgraph PIPELINE["Airflow DAGs"]
        D1["01_cx_ingestion\nInvoke Lambdas"]
        D2["01b_cx_s3_to_redshift\nCOPY S3 → Redshift"]
        D3["02_transform_cx\ndbt run"]
    end

    D1 --> D2
    D2 --> D3
    style PIPELINE fill:#017CEE,color:#fff
```

## Setup & Scaffolding
The repository has been scaffolded to align with this CX architecture, with empty files ready for the development of the Lambda generators, Airflow DAGs, and dbt models.
