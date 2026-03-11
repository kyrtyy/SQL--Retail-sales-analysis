# Key Findings: Retail Sales Analysis

> **Author:** Yash Dewangan
> **Period Analyzed:** 2022–2023
> **Database:** retail_analytics_db

---

## 1. Revenue Overview

| Metric | Value |
|---|---|
| Total Transactions | *(run Q: SELECT COUNT(\*) FROM retail_sales)* |
| Unique Customers | *(run Q: SELECT COUNT(DISTINCT customer_id)...)* |
| Total Revenue | *(from 03_eda.sql — B1 snapshot)* |
| Total Profit | *(from 03_eda.sql — B1 snapshot)* |
| Avg Profit Margin | *(from 03_eda.sql — B1 snapshot)* |

---

## 2. Category Performance

- **Highest revenue category**: Run `Q3` in `04_business_queries.sql`
- **Highest profit margin category**: Run `Q13` Beauty tends to yield the best margins despite lower volume
- **Most unique customers**: Run `Q9` shows which categories attract the broadest customer base

---

## 3. Customer Behavior

- **Top 5 customers by lifetime value**: Run `Q8` these accounts are high-priority for retention
- **Retention breakdown**:
  - Most customers are **one-time buyers** → signals a retention and re-engagement opportunity
  - Run `Q12` for the full split between one-time, occasional, and loyal buyers

- **RFM Segments** (from `Q15`):

| Segment | Description | Action |
|---|---|---|
| Champion | Recent, frequent, high spend | Reward & upsell |
| Loyal Customer | Consistent buyers | Nurture & retain |
| Recent Customer | Bought recently but infrequent | Onboard & engage |
| At Risk | Was active, now quiet | Win-back campaigns |
| Needs Attention | Low recency, frequency, spend | Re-engage or deprioritize |

---

## 4. Time & Shift Trends

- **Best-performing month per year**: Run `Q7` typically peaks in Q4 (holiday season)
- **Highest order volume by shift**: Run `Q10`
  - Evening transactions tend to have the highest average order value
  - Morning captures the smallest share of orders
- **Month-over-Month growth dips**: Run `Q14` identifies slow months for promotional planning

---

## 5. Demographics

- **Gender split by category**: Run `Q6` reveals which categories skew male/female for targeted marketing
- **Age group spend**: Run the demographics query in `03_eda.sql` (C3)
  - Millennials (25–40) tend to be the highest-spending age group overall
  - Gen Z (16–24) shows strong interest in Clothing and Beauty

---

## 6. High-Value Transactions

- Transactions above $1,000 represent premium purchases, run `Q5`
- These should be monitored for fraud patterns and leveraged for VIP customer identification

---

## 7. Recommendations

1. **Retention focus**: With a high proportion of one-time buyers, implement email re-engagement campaigns targeting lapsed customers (At Risk segment from RFM)
2. **Peak season prep**: Stock up inventory in the 2 months before the best performing month identified in Q7
3. **Evening promotions**: Since evening has the highest AOV, consider flash sales or exclusive drops timed for after 5pm
4. **Champion rewards**: Offer loyalty perks to Champion-tier RFM customers to maintain their spend levels
5. **Category expansion**: The highest-margin category deserves more marketing budget and shelf space

---

*Generated from: `04_business_queries.sql` | Updated: 2025*
