-- Ensure we are using the characters database
USE `acore_characters`;

-- Create the accountwide_gold table if it doesn't already exist
CREATE TABLE IF NOT EXISTS accountwide_gold (
    accountId INT UNSIGNED NOT NULL PRIMARY KEY,
    gold BIGINT UNSIGNED NOT NULL DEFAULT 0
);

-- Create the accountwide_currency table if it doesn't already exist
CREATE TABLE IF NOT EXISTS accountwide_currency (
    accountId INT NOT NULL,
    currencyId INT NOT NULL,
    count INT NOT NULL,
    PRIMARY KEY (accountId, currencyId)
);

