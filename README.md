# Construction-Site-Risk-Cost-Analysis-SQL-
Analyzed 50,000 minute-level readings from a construction site monitoring system (Jan–Feb 2023) using SQL to understand what operational factors — machinery usage, material shortages, worker allocation — drive cost overruns, schedule delays, and safety risk.


Q1: Does active machinery status affect cost and risk?

sqlSELECT machinery_status,
       ROUND(AVG(cost_deviation),2) AS avg_cost_dev,
       ROUND(AVG(risk_score),2)      AS avg_risk,
       COUNT(*)                      AS n
FROM site_readings
GROUP BY machinery_status;

Finding: Cost deviation and risk score were roughly similar regardless
of machinery status (active vs. idle), suggesting machinery status alone
isn't a major cost driver on its own — other factors matter more.

Q2: Which optimization action correlates with the best/worst outcomes?

sqlSELECT optimization_suggestion,
       ROUND(AVG(cost_deviation),2)  AS avg_cost_dev,
       ROUND(AVG(time_deviation),2)  AS avg_time_dev,
       SUM(safety_incidents)         AS total_safety_incidents,
       COUNT(*)                      AS n
FROM site_readings
GROUP BY optimization_suggestion
ORDER BY avg_cost_dev DESC;

Finding: Periods flagged "Reallocate Workers" showed the strongest
cost improvement (avg cost deviation of -32.46, i.e. under budget),
while "Adjust Schedule" periods ran the most over budget (+15.28).
This suggests worker reallocation is a more cost-effective lever than
schedule adjustments.


Q3: Impact of material shortage alerts on cost and progress

sqlSELECT material_shortage_alert,
       ROUND(AVG(cost_deviation),2)        AS avg_cost_dev,
       ROUND(AVG(task_progress)*100,2)     AS avg_task_progress_pct,
       COUNT(*)                            AS n
FROM site_readings
GROUP BY material_shortage_alert;

Finding: When a material shortage alert was active, average cost
deviation flipped from -5.79 (under budget) to +0.49 (over
budget) — showing material shortages have a measurable, direct cost
impact.


Q4: 7-day rolling average of risk score (window function)

sqlWITH daily AS (
  SELECT date, ROUND(AVG(risk_score),2) AS avg_risk
  FROM site_readings
  GROUP BY date
)
SELECT date, avg_risk,
       ROUND(AVG(avg_risk) OVER (
             ORDER BY date
             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS rolling_7day_avg
FROM daily
ORDER BY date;

Finding: Daily risk scores fluctuate day to day, but the 7-day
rolling average smooths this out and hovers consistently around
~50, showing no major upward/downward long-term trend across the
two-month period — risk stayed roughly stable rather than escalating.


Q5: Top 5 highest-risk days (ranked)

sqlWITH daily AS (
  SELECT date,
         ROUND(AVG(risk_score),2) AS avg_risk,
         SUM(safety_incidents)    AS incidents
  FROM site_readings
  GROUP BY date
)
SELECT date, avg_risk, incidents,
       RANK() OVER (ORDER BY avg_risk DESC) AS risk_rank
FROM daily
ORDER BY avg_risk DESC
LIMIT 5;

Finding: Identified the 5 highest-risk days (e.g., Jan 3, Jan 24,
Feb 1), each with elevated safety incident counts — these are the days
that would warrant a safety review in a real operational setting.
