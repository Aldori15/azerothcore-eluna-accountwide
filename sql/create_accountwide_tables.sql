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

-- -- Create the accountwide_professions table if it doesn't already exist (currently a WIP and not used)
-- CREATE TABLE IF NOT EXISTS `accountwide_professions` (
--   `accountId` INT NOT NULL,
--   `professionId` INT NOT NULL,
--   `currentVal` SMALLINT NOT NULL DEFAULT 0,
--   `maxVal` SMALLINT NOT NULL DEFAULT 0,
--   PRIMARY KEY (`accountId`, `professionId`)
-- );

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