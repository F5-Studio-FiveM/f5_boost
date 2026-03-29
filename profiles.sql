-- f5_boost | Player Profiles
-- Auto-created on resource start. This file is provided as reference.

CREATE TABLE IF NOT EXISTS `f5_boost_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL COMMENT 'Player license2/license identifier',
    `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Profile slot (1-5)',
    `name` VARCHAR(50) NOT NULL COMMENT 'Profile display name',
    `settings` LONGTEXT NOT NULL COMMENT 'JSON-encoded settings snapshot',
    `is_default` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Auto-apply on join',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_identifier_slot` (`identifier`, `slot`),
    INDEX `idx_identifier_default` (`identifier`, `is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
