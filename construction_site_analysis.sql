-- =====================================================================
-- Construction Site Risk & Cost Analysis
-- Dataset: 50,000 minute-level readings from a construction site
--          monitoring system (Jan-Feb 2023)
-- Tool: SQLite
-- =====================================================================

-- Q1: Does active machinery status affect cost deviation and risk?
SELECT machinery_status,
       ROUND(AVG(cost_deviation),2) AS avg_cost_dev,
       ROUND(AVG(risk_score),2)      AS avg_risk,
       COUNT(*)                      AS n
FROM site_readings
GROUP BY machinery_status;

-- Q2: Which optimization action correlates with the best/worst
--     cost and time outcomes? (helps prioritize interventions)
SELECT optimization_suggestion,
       ROUND(AVG(cost_deviation),2)  AS avg_cost_dev,
       ROUND(AVG(time_deviation),2)  AS avg_time_dev,
       SUM(safety_incidents)         AS total_safety_incidents,
       COUNT(*)                      AS n
FROM site_readings
GROUP BY optimization_suggestion
ORDER BY avg_cost_dev DESC;

-- Q3: Impact of material shortage alerts on cost deviation and
--     task progress
SELECT material_shortage_alert,
       ROUND(AVG(cost_deviation),2)        AS avg_cost_dev,
       ROUND(AVG(task_progress)*100,2)     AS avg_task_progress_pct,
       COUNT(*)                            AS n
FROM site_readings
GROUP BY material_shortage_alert;

-- Q4: 7-day rolling average of daily risk score (window function)
--     -- smooths daily noise to reveal real risk trend
WITH daily AS (
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

-- Q5: Top 5 highest-risk days, ranked (window function: RANK)
--     -- used to flag days needing safety review
WITH daily AS (
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
