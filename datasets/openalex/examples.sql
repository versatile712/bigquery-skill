-- OpenAlex on CWTS Leiden — canonical query patterns
-- Version rule: only institution_type → openalex_2024aug ; everything else → openalex_2025aug

-- ============================================================
-- 1. Works by author, single year (no institution join)
-- ============================================================
WITH w AS (
  SELECT work_id, pub_year
  FROM `cwts-leiden.openalex_2025aug.work`
  WHERE pub_year = 2020
  LIMIT 1000
)
SELECT w.work_id, w.pub_year, wa.author_seq, a.author_id, a.author
FROM w
JOIN `cwts-leiden.openalex_2025aug.work_author` AS wa USING (work_id)
JOIN `cwts-leiden.openalex_2025aug.author`      AS a  USING (author_id);

-- ============================================================
-- 2. Works × institutions (same-dataset JOIN on 2025aug)
-- ============================================================
SELECT w.work_id, w.pub_year, i.institution_id, i.institution
FROM `cwts-leiden.openalex_2025aug.work`                         AS w
JOIN `cwts-leiden.openalex_2025aug.work_affiliation_institution` AS wai USING (work_id)
JOIN `cwts-leiden.openalex_2025aug.institution`                  AS i   USING (institution_id)
WHERE w.pub_year BETWEEN 2018 AND 2022
LIMIT 500;

-- ============================================================
-- 3. Citation network slice
-- ============================================================
SELECT citing_work_id, cited_work_id, pub_year
FROM `cwts-leiden.openalex_2025aug.citation`
WHERE pub_year BETWEEN 2018 AND 2022
LIMIT 1000;

-- ============================================================
-- 4. Author affiliation history
-- ============================================================
SELECT ai.author_id, a.author, ai.institution_seq, i.institution_id, i.institution
FROM `cwts-leiden.openalex_2025aug.author_institution` AS ai
JOIN `cwts-leiden.openalex_2025aug.institution`        AS i USING (institution_id)
JOIN `cwts-leiden.openalex_2025aug.author`             AS a USING (author_id)
WHERE ai.author_id IN ('A5023888391', 'A5012345678')
ORDER BY ai.author_id, ai.institution_seq;

-- ============================================================
-- 5. Author's ORCID lookup (bridge to ORCID dataset)
-- ============================================================
SELECT author_id, author, orcid
FROM `cwts-leiden.openalex_2025aug.author`
WHERE orcid IS NOT NULL
LIMIT 100;

-- ============================================================
-- 6. Institution + type (the only mixed-dataset JOIN)
-- ============================================================
SELECT i.institution_id, i.institution, it.institution_type
FROM `cwts-leiden.openalex_2025aug.institution`        AS i
JOIN `cwts-leiden.openalex_2024aug.institution_type`   AS it
  USING (institution_type_id)
LIMIT 100;
