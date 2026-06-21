/*CREATE TABLE customers (
    "Customer ID" INT,
    "Age" INT,
    "Gender" TEXT,
    "Item Purchased" TEXT,
    "Category" TEXT,
    "Purchase Amount (USD)" FLOAT,
    "Location" TEXT,
    "Size" TEXT,
    "Color" TEXT,
    "Season" TEXT,
    "Review Rating" FLOAT,
    "Subscription Status" TEXT,
    "Shipping Type" TEXT,
    "Discount Applied" INT,
    "Promo Code Used" TEXT,
    "Previous Purchases" INT,
    "Payment Method" TEXT,
    "Frequency of Purchases" TEXT,
    "Rating_Imputed" INT,
    "Promo Used" INT,
    "Subscription Used" INT,
    "Freq_per_Year" INT,
    "Est_Annual_Spend" FLOAT,
    "CLV_Score" FLOAT,
    "Value_Tier" TEXT,
    "Promo_Dependent" INT,
    "Satisfaction_Flag" TEXT,
    "Age_Group" TEXT,
    "Loyalty_Score_A" FLOAT,
    "Loyal_A" INT,
    "Loyalty_Score_B" FLOAT,
    "Loyal_B" INT,
    "Loyal_Both" INT,
    "Segment" TEXT
);

SELECT COUNT(*) FROM customers;*/

-- ============================================================
-- PROJECT   : Decoding Customer Value - A SQL Driven Retention Strategy
-- CLUB      : Consulting & Analytics Club, IIT Guwahati
-- PHASE     : 2 - Customer Segmentation & Analysis (SQL)
-- DATABASE  : fashion_brand
-- TABLE     : customers (3900 rows, loaded from customers_phase1.csv)
-- ============================================================


-- ============================================================
-- QUERY 1: Loyal vs Discount-Only Customers
-- ============================================================
-- BUSINESS QUESTION:
--   Who are the genuinely loyal customers vs those who only
--   buy when there is a discount?
--
-- LOGIC:
--   Loyal_Both = 1 means the customer qualifies as loyal under
--   BOTH Loyalty Definition A (frequency + tenure) and
--   Loyalty Definition B (CLV + satisfaction). Promo_Dependent = 1
--   means the customer used both a discount AND a promo code.
--   Comparing these two flags across segments reveals who is
--   truly loyal vs who is just a discount chaser.
--
-- KEY FINDINGS:
--   - Champions (551 customers): 74.4% genuinely loyal, 0% promo
--     dependent. These customers buy regularly without needing
--     any discount incentive. They are the brand's most valuable asset.
--   - Promo Reliant & Bargain Hunters: 100% promo dependent with
--     near 0% genuine loyalty. They will stop buying the moment
--     discounts are removed. Their revenue is not sustainable.
--   - At-Risk Loyalists: 44% genuine loyalty but declining value.
--     They need targeted retention action before they disengage.
-- ============================================================

SELECT 
    "Segment",
    COUNT(*) AS customer_count,
    ROUND(AVG("Purchase Amount (USD)")::numeric, 2) AS avg_spend,
    ROUND((AVG("Promo_Dependent") * 100)::numeric, 1) AS promo_dependency_pct,
    ROUND((AVG("Loyal_Both") * 100)::numeric, 1) AS genuinely_loyal_pct,
    ROUND(AVG("Review Rating")::numeric, 2) AS avg_rating
FROM customers
GROUP BY "Segment"
ORDER BY genuinely_loyal_pct DESC;


-- ============================================================
-- QUERY 2: Behavioral Patterns by Value Tier
-- ============================================================
-- BUSINESS QUESTION:
--   What behavioral patterns today predict high customer
--   value over time?
--
-- LOGIC:
--   Value_Tier is derived from CLV_Score quartiles (Low, Mid,
--   High, Premium). By comparing behavioral metrics across tiers
--   we can identify which signals distinguish a Premium customer
--   from a Low one — giving the brand a predictive profile to
--   act on early.
--
-- KEY FINDINGS:
--   - Purchase frequency (Freq_per_Year) is the strongest
--     differentiator: Premium customers buy 38x/year vs Low
--     customers who buy only 2.4x/year.
--   - Age is NOT a differentiator — all tiers average ~44 years,
--     meaning the brand should not target by age alone.
--   - Previous Purchases are higher for Premium (29.7) vs Low
--     (21.7), showing that tenure compounds value over time.
--   - Actionable insight: Focus on increasing purchase frequency
--     among Mid-tier customers to push them into High/Premium.
-- ============================================================

SELECT 
    "Value_Tier",
    COUNT(*) AS customer_count,
    ROUND(AVG("Age")::numeric, 1) AS avg_age,
    ROUND(AVG("Freq_per_Year")::numeric, 1) AS avg_freq_per_year,
    ROUND(AVG("Previous Purchases")::numeric, 1) AS avg_prev_purchases,
    ROUND(AVG("Review Rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("Subscription Used")::numeric * 100, 1) AS subscription_pct,
    ROUND(AVG("Est_Annual_Spend")::numeric, 2) AS avg_annual_spend
FROM customers
GROUP BY "Value_Tier"
ORDER BY avg_annual_spend DESC;


-- ============================================================
-- QUERY 3: Geography - Organic Demand vs Discount-Driven Volume
-- ============================================================
-- BUSINESS QUESTION:
--   Which geographies are commercially underlevered?
--   Which regions show genuine brand pull vs discount dependency?
--
-- LOGIC:
--   States with HIGH avg_annual_spend AND LOW promo_dependency_pct
--   indicate customers who pay full price willingly — genuine brand
--   pull. States with high spend but high promo dependency are
--   discount-driven markets where revenue is fragile.
--   Sorted by spend descending, promo dependency ascending to
--   surface the best organic opportunity markets first.
--
-- KEY FINDINGS:
--   - Tennessee: High spend ($1258) + lowest promo dependency
--     (36.4%) = strongest genuine brand pull. A priority market
--     for organic/non-discount marketing campaigns.
--   - Illinois & Alaska: High spend with ~40% promo dependency.
--     Strong markets with room to reduce discount reliance.
--   - Indiana: Highest promo dependency (57%) despite decent spend.
--     Revenue here is discount-driven and at risk if promos are cut.
--   - Underlevered opportunity: Tennessee, Illinois, Alaska have
--     not been deliberately targeted yet but show strong organic pull.
-- ============================================================

SELECT 
    "Location",
    COUNT(*) AS customer_count,
    ROUND(AVG("Est_Annual_Spend")::numeric, 2) AS avg_annual_spend,
    ROUND((AVG("Promo_Dependent") * 100)::numeric, 1) AS promo_dependency_pct,
    ROUND(AVG("CLV_Score")::numeric, 2) AS avg_clv,
    ROUND(AVG("Review Rating")::numeric, 2) AS avg_rating
FROM customers
GROUP BY "Location"
ORDER BY avg_annual_spend DESC, promo_dependency_pct ASC
LIMIT 15;


-- ============================================================
-- QUERY 4: Promo Strategy Restructuring
-- ============================================================
-- BUSINESS QUESTION:
--   How should the brand restructure its promotional strategy
--   to protect margins without losing volume?
--
-- LOGIC:
--   Segments with HIGH CLV + HIGH promo dependency are the
--   prime candidates for discount sunset. These customers
--   already demonstrate high spending behavior — they are
--   likely to continue buying even without discounts, making
--   them the safest group to test full-price conversion on.
--   Segments with LOW CLV + HIGH promo dependency (Bargain
--   Hunters) should simply be deprioritized entirely.
--
-- KEY FINDINGS:
--   - Promo Reliant + Premium (424 customers): CLV of 8537,
--     100% promo dependent, $2601 avg spend. Nearly identical
--     CLV to Champions (8474) who need zero discounts. This is
--     the #1 priority for promo sunset — start reducing discounts
--     here with a 3-month gradual rollout.
--   - Champions + Premium (551 customers): Same CLV as Promo
--     Reliant but 0% promo dependency. Proof that Premium
--     customers CAN and DO buy at full price.
--   - Bargain Hunters (Low+Mid): 100% promo dependent, lowest
--     CLV. Not worth discounting — deprioritize these segments
--     from promotional spend entirely.
-- ============================================================

SELECT 
    "Segment",
    "Value_Tier",
    COUNT(*) AS customer_count,
    ROUND((AVG("Promo_Dependent") * 100)::numeric, 1) AS promo_dependency_pct,
    ROUND(AVG("CLV_Score")::numeric, 2) AS avg_clv,
    ROUND(AVG("Est_Annual_Spend")::numeric, 2) AS avg_annual_spend,
    ROUND((AVG(CASE WHEN "Satisfaction_Flag" = 'Promoter' THEN 1 ELSE 0 END) * 100)::numeric, 1) AS promoter_pct
FROM customers
GROUP BY "Segment", "Value_Tier"
ORDER BY avg_clv DESC;


-- ============================================================
-- QUERY 5: Ideal Customer Profile (ICP)
-- ============================================================
-- BUSINESS QUESTION:
--   What does the brand's ideal customer look like, and how
--   can the brand acquire more of them?
--
-- LOGIC:
--   Filters for customers who are: (1) genuinely loyal under
--   both definitions (Loyal_Both = 1), (2) in the top two
--   value tiers (High or Premium), AND (3) promo independent
--   (Promo_Dependent = 0). This combination identifies the
--   brand's most valuable, sustainable customer type.
--   Grouped by demographic and behavioral attributes to build
--   a specific, actionable profile for the marketing team.
--
-- KEY FINDINGS:
--   - Highest CLV profile: Female, 26-35, Clothing, Credit Card,
--     Fall season — avg CLV of 13,432 and $3,575 annual spend.
--     This is the single most valuable customer type.
--   - Dominant ICP: Female 26-35 and Male 36-45, Clothing category,
--     Credit Card or Cash payment, active in Winter and Spring.
--   - Almost all ideal customers are Promoters (rating >= 4.0),
--     meaning they are also likely to refer others organically.
--   - Actionable: Marketing team should target Female 26-35,
--     Clothing category, Credit Card users in Fall/Winter
--     campaigns — specifically in Tennessee and Illinois markets
--     (from Query 3) for maximum impact.
-- ============================================================

SELECT 
    "Age_Group",
    "Gender",
    "Category",
    "Payment Method",
    "Season",
    "Satisfaction_Flag",
    COUNT(*) AS count,
    ROUND(AVG("CLV_Score")::numeric, 2) AS avg_clv,
    ROUND(AVG("Est_Annual_Spend")::numeric, 2) AS avg_annual_spend
FROM customers
WHERE "Loyal_Both" = 1 
    AND "Value_Tier" IN ('High', 'Premium')
    AND "Promo_Dependent" = 0
GROUP BY "Age_Group", "Gender", "Category", "Payment Method", "Season", "Satisfaction_Flag"
ORDER BY count DESC
LIMIT 15;


-- ============================================================
-- END OF QUERIES
-- ============================================================