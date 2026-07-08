-- Ensure we are using the characters database
USE `acore_characters`;

-- Create the accountwide_achievements table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_achievements` (
    `accountId` INT UNSIGNED NOT NULL,
    `achievementId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `achievementId`)
);

-- Create the accountwide_criteria_max table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_criteria_max` (
  `accountId` INT UNSIGNED NOT NULL,
  `criteria` INT UNSIGNED NOT NULL,
  `counter` INT UNSIGNED NOT NULL,
  `date` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`accountId`, `criteria`)
) ENGINE=InnoDB;

-- Create the accountwide_currency table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_currency` (
    `accountId` INT UNSIGNED NOT NULL,
    `currencyId` INT UNSIGNED NOT NULL,
    `count` INT NOT NULL,
    PRIMARY KEY (`accountId`, `currencyId`)
);

-- Create the accountwide_money table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_money` (
    `accountId` INT UNSIGNED NOT NULL PRIMARY KEY,
    `money` BIGINT UNSIGNED NOT NULL DEFAULT 0
);

-- Create the accountwide_mounts table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_mounts` (
    `accountId` INT UNSIGNED NOT NULL,
    `mountSpellId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `mountSpellId`)
);

-- Create the accountwide_pets table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_pets` (
    `accountId` INT UNSIGNED NOT NULL,
    `petSpellId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `petSpellId`)
);

-- Create the accountwide_professions table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_professions` (
  `accountId` INT UNSIGNED NOT NULL,
  `professionId` SMALLINT UNSIGNED NOT NULL,
  `currentVal` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `maxVal` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountId`, `professionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_profession_recipes table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_profession_recipes` (
  `accountId` INT UNSIGNED NOT NULL,
  `spellId` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`accountId`, `spellId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_profession_recipe_lookup table if it doesn't already exist
-- Populate this table with accountwide_profession_recipe_lookup.sql
CREATE TABLE IF NOT EXISTS `accountwide_profession_recipe_lookup` (
  `professionId` SMALLINT UNSIGNED NOT NULL,
  `spellId` INT UNSIGNED NOT NULL,
  `minSkillLineRank` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `raceMask` INT UNSIGNED NOT NULL DEFAULT 0,
  `classMask` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`spellId`),
  KEY `idx_professionId` (`professionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_professions_seed table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_professions_seed` (
  `accountId` INT UNSIGNED NOT NULL PRIMARY KEY,
  `skillsSeeded` TINYINT(1) NOT NULL DEFAULT 0,
  `recipesSeeded` TINYINT(1) NOT NULL DEFAULT 0,
  `seeded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_pvp_rank table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_pvp_rank` (
    `accountId` INT UNSIGNED NOT NULL PRIMARY KEY,
    `arenaPoints` INT UNSIGNED NOT NULL DEFAULT 0,
    `totalHonorPoints` INT UNSIGNED NOT NULL DEFAULT 0,
    `todayHonorPoints` INT UNSIGNED NOT NULL DEFAULT 0,
    `yesterdayHonorPoints` INT UNSIGNED NOT NULL DEFAULT 0,
    `totalKills` INT UNSIGNED NOT NULL DEFAULT 0,
    `todayKills` INT UNSIGNED NOT NULL DEFAULT 0,
    `yesterdayKills` INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table is now obsolete, so remove it for players who were using the table prior to this change
DROP TABLE IF EXISTS `accountwide_reputation`;

-- Create the accountwide_reputation_seed table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_reputation_seed` (
  `accountId` INT UNSIGNED NOT NULL PRIMARY KEY,
  `seeded` TINYINT(1) NOT NULL DEFAULT 0,
  `seeded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create the accountwide_taxi_alliance table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_taxi_alliance` (
    `accountId` INT UNSIGNED NOT NULL,
    `nodeId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `nodeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_taxi_horde table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_taxi_horde` (
    `accountId` INT UNSIGNED NOT NULL,
    `nodeId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `nodeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create the accountwide_titles table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_titles` (
    `accountId` INT UNSIGNED NOT NULL,
    `titleId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `titleId`)
);