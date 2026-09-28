-- ============================================================
-- Create dashboard-ready Pokémon dataset
-- ============================================================
-- This query combines Pokémon type, base stats, and species
-- information into a single analysis-ready table for the
-- Looker Studio dashboard.
-- ============================================================

CREATE OR REPLACE TABLE
  `proud-lamp-305020.pokemon_analytics.pokemon_dashboard` AS


-- ============================================================
-- 1. Prepare Pokémon type information
-- ============================================================
-- Convert the row-level type data into primary and secondary
-- type columns for each Pokémon.
-- ============================================================

WITH pokemon_types AS (

  SELECT
    p.id AS pokemon_id,
    p.identifier AS pokemon_name,

    MAX(CASE
      WHEN pt.slot = 1 THEN t.identifier
    END) AS primary_type,

    MAX(CASE
      WHEN pt.slot = 2 THEN t.identifier
    END) AS secondary_type

  FROM
    `proud-lamp-305020.pokemon_analytics.pokemon` AS p

  INNER JOIN
    `proud-lamp-305020.pokemon_analytics.pokemon_types` AS pt
    ON p.id = pt.pokemon_id

  INNER JOIN
    `proud-lamp-305020.pokemon_analytics.types` AS t
    ON pt.type_id = t.id

  GROUP BY
    p.id,
    p.identifier
),


-- ============================================================
-- 2. Prepare Pokémon base statistics
-- ============================================================
-- Transform the row-level stat data into separate columns
-- for HP, Attack, Defense, Special Attack, Special Defense,
-- and Speed.
-- ============================================================

pokemon_stats AS (

  SELECT
    pokemon_id,

    MAX(IF(stat_id = 1, base_stat, NULL)) AS hp,
    MAX(IF(stat_id = 2, base_stat, NULL)) AS attack,
    MAX(IF(stat_id = 3, base_stat, NULL)) AS defense,
    MAX(IF(stat_id = 4, base_stat, NULL)) AS special_attack,
    MAX(IF(stat_id = 5, base_stat, NULL)) AS special_defense,
    MAX(IF(stat_id = 6, base_stat, NULL)) AS speed

  FROM
    `proud-lamp-305020.pokemon_analytics.pokemon_stats`

  GROUP BY
    pokemon_id
)


-- ============================================================
-- 3. Create the final dashboard dataset
-- ============================================================
-- Combine Pokémon type, base stats, and species information
-- into one table.
-- ============================================================

SELECT
  pt.pokemon_id,
  pt.pokemon_name,
  pt.primary_type,
  pt.secondary_type,

  ps.hp,
  ps.attack,
  ps.defense,
  ps.special_attack,
  ps.special_defense,
  ps.speed,

  -- Calculate the combined base stat total
  (
    ps.hp
    + ps.attack
    + ps.defense
    + ps.special_attack
    + ps.special_defense
    + ps.speed
  ) AS total_stats,

  species.generation_id AS generation,
  species.is_legendary,
  species.is_mythical,

  -- Used to identify the default Pokémon form
  p.is_default

FROM
  pokemon_types AS pt

INNER JOIN
  pokemon_stats AS ps
  ON pt.pokemon_id = ps.pokemon_id

INNER JOIN
  `proud-lamp-305020.pokemon_analytics.pokemon` AS p
  ON pt.pokemon_id = p.id

INNER JOIN
  `proud-lamp-305020.pokemon_analytics.pokemon_species` AS species
  ON p.species_id = species.id;
