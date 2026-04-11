# Sales Funnel & Revenue Leakage Analysis

## Project Overview
Analyzing a CRM sales pipeline dataset to identify funnel drop-offs 
and estimate recoverable revenue leakage.

## Dataset
- Source: Kaggle — CRM Sales Opportunities
- 8,800 deals | 4 tables | 14 months of pipeline data (Oct 2016 - Dec 2017)

## Day 1 — Data Exploration Complete
- Loaded and explored all 5 CSV files
- Understood funnel structure: Prospecting → Engaging → Won / Lost
- Identified 6,711 closed deals and 2,089 active deals
- Spotted potential revenue leakage in zero-value Won deals
- Null values investigated and explained

  ## Day 2 — Funnel Analysis & Revenue Leakage
- Built complete sales funnel with conversion rates
- Overall win rate: 48.2% (every second deal lost)
- Identified $2.69M in recoverable revenue (26.9% of won revenue)
- GTX Basic product responsible for 21.1% of all lost deals
- Central region accounts for 39.4% of all lost deals

## Tools Used
- Python, Pandas, NumPy
- Google Colab
