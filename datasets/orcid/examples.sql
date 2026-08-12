-- ORCID — placeholder examples. Adjust `<your-project>.orcid_<yyyymm>` once loaded.

-- 1. Simple employment history
SELECT orcid, role_title, organization_name, ror_id, start_year, end_year
FROM `<your-project>.orcid_<yyyymm>.employment`
WHERE orcid = '0000-0002-1825-0097'
ORDER BY start_year;

-- 2. Employees currently at a given ROR-identified institution
SELECT orcid, role_title, start_year
FROM `<your-project>.orcid_<yyyymm>.employment`
WHERE ror_id = 'https://ror.org/01rxvg760'   -- example
  AND end_year IS NULL;

-- 3. Join ORCID employment with OpenAlex authorship (bridging table pattern)
WITH bridge AS (
  SELECT author_id, orcid
  FROM `cwts-leiden.openalex_2025aug.author`
  WHERE orcid IS NOT NULL
)
SELECT b.author_id, e.role_title, e.organization_name, e.start_year, e.end_year
FROM bridge AS b
JOIN `<your-project>.orcid_<yyyymm>.employment` AS e USING (orcid)
LIMIT 100;
