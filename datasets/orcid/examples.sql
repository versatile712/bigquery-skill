-- ORCID on Dimensions BigQuery — canonical query patterns
-- Dataset: ds-open-datasets.orcid.summaries_2025 (default; also summaries_2023 / summaries_2024)
-- Verified via INFORMATION_SCHEMA + Table.schema on 2026-08-12.

-- ============================================================
-- 1. Active ORCID count (near-free — reads history metadata)
-- ============================================================
SELECT COUNT(*) AS active_orcids
FROM `ds-open-datasets.orcid.summaries_2025`
WHERE history.deactivation_date IS NULL;

-- ============================================================
-- 2. New ORCIDs created per year
-- ============================================================
SELECT
  EXTRACT(YEAR FROM TIMESTAMP(history.submission_date)) AS year,
  COUNT(*) AS n
FROM `ds-open-datasets.orcid.summaries_2025`
WHERE history.deactivation_date IS NULL
GROUP BY year
ORDER BY year;

-- ============================================================
-- 3. Full employment history of a SINGLE ORCID
--    (talent-mobility use case: high-confidence job transitions)
-- ============================================================
WITH target AS (
  SELECT '0000-0002-1825-0097' AS orcid_path  -- placeholder
),
emp AS (
  SELECT
    orcid_identifier.path AS orcid_path,
    r.role_title,
    r.department_name,
    r.organization.name AS org_name,
    r.organization.address.country AS country,
    r.organization.disambiguated_organization.identifier AS org_id,
    r.organization.disambiguated_organization.source     AS org_source,
    SAFE_CAST(r.start_date.year AS INT64) AS start_year,
    SAFE_CAST(r.end_date.year   AS INT64) AS end_year
  FROM `ds-open-datasets.orcid.summaries_2025`,
       UNNEST(activities.employments.groups) AS g,
       UNNEST(g.records) AS r
  WHERE orcid_identifier.path IN (SELECT orcid_path FROM target)
)
SELECT *
FROM emp
ORDER BY start_year;

-- ============================================================
-- 4. Employment transitions in a single year (large — dry-run first!)
--    Identifies job STARTS in a target year, keyed by ROR
-- ============================================================
SELECT
  orcid_identifier.path AS orcid_path,
  r.role_title,
  r.organization.name AS org_name,
  r.organization.disambiguated_organization.identifier AS ror_id
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.employments.groups) AS g,
     UNNEST(g.records) AS r
WHERE r.start_date.year = '2023'
  AND r.organization.disambiguated_organization.source = 'ROR'
LIMIT 1000;

-- ============================================================
-- 5. ORCID → OpenAlex bridge (talent-mobility ground truth)
--    Match ORCID employment records to OpenAlex authors via ORCID path.
-- ============================================================
WITH orcid_emp AS (
  SELECT
    orcid_identifier.path AS orcid_path,
    r.role_title,
    r.organization.name AS org_name,
    r.organization.disambiguated_organization.identifier AS ror_id,
    SAFE_CAST(r.start_date.year AS INT64) AS start_year,
    SAFE_CAST(r.end_date.year   AS INT64) AS end_year
  FROM `ds-open-datasets.orcid.summaries_2025`,
       UNNEST(activities.employments.groups) AS g,
       UNNEST(g.records) AS r
  WHERE r.organization.disambiguated_organization.source = 'ROR'
),
oa AS (
  SELECT
    author_id,
    author,
    REGEXP_EXTRACT(orcid, r'([\dX]{4}-[\dX]{4}-[\dX]{4}-[\dX]{4})') AS orcid_path
  FROM `cwts-leiden.openalex_2025aug.author`
  WHERE orcid IS NOT NULL
)
SELECT
  oa.author_id,
  oa.author,
  oe.role_title,
  oe.org_name,
  oe.ror_id,
  oe.start_year,
  oe.end_year
FROM oa
JOIN orcid_emp AS oe USING (orcid_path)
LIMIT 500;

-- ============================================================
-- 6. Educations for a set of ORCIDs (matched pattern to #3)
-- ============================================================
SELECT
  orcid_identifier.path AS orcid_path,
  r.role_title AS degree,
  r.organization.name AS org_name,
  r.organization.address.country AS country,
  SAFE_CAST(r.start_date.year AS INT64) AS start_year,
  SAFE_CAST(r.end_date.year   AS INT64) AS end_year
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.educations.groups) AS g,
     UNNEST(g.records) AS r
WHERE orcid_identifier.path IN ('0000-0002-1825-0097', '0000-0003-1613-5981');

-- ============================================================
-- 7. Works claimed by a single ORCID, with DOI
-- ============================================================
SELECT
  orcid_identifier.path AS orcid_path,
  r.title.title AS work_title,
  r.type,
  r.publication_date.year AS pub_year,
  ARRAY_AGG(STRUCT(id.type, id.value)) AS identifiers
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.works.groups) AS g,
     UNNEST(g.records) AS r,
     UNNEST(g.external_ids.identifiers) AS id
WHERE orcid_identifier.path = '0000-0002-1825-0097'
GROUP BY orcid_path, work_title, r.type, pub_year;

-- ============================================================
-- 8. Peer-review activity (note the DOUBLE .groups upstream quirk)
-- ============================================================
SELECT
  orcid_identifier.path AS orcid_path,
  r.reviewer_role,
  r.review_type,
  r.convening_organization.name AS convening_org
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.peer_reviews.groups) AS g,
     UNNEST(g.groups) AS gg,
     UNNEST(gg.records) AS r
WHERE orcid_identifier.path = '0000-0002-1825-0097';
