-- Ensure we are using the characters database
USE `acore_characters`;

-- Create the accountwide_achievements table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_achievements` (
    `accountId` INT UNSIGNED NOT NULL,
    `achievementId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `achievementId`)
);

-- Create the accountwide_currency table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_currency` (
    `accountId` INT NOT NULL,
    `currencyId` INT NOT NULL,
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
    `accountId` INT NOT NULL,
    `mountSpellId` INT NOT NULL,
    PRIMARY KEY (`accountId`, `mountSpellId`)
);

-- Create the accountwide_pets table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_pets` (
    `accountId` INT NOT NULL,
    `petSpellId` INT NOT NULL,
    PRIMARY KEY (`accountId`, `petSpellId`)
);

-- Create the accountwide_reputation table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_reputation` (
    `accountId` INT UNSIGNED NOT NULL,
    `factionId` INT UNSIGNED NOT NULL,
    `standing` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `factionId`)
);

-- Create the accountwide_reputation table if it doesn't already exist
CREATE TABLE IF NOT EXISTS `accountwide_reputation` (
    `accountId` INT UNSIGNED NOT NULL,
    `factionId` INT UNSIGNED NOT NULL,
    `standing` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`accountId`, `factionId`)
);