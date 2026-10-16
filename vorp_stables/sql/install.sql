-- Additive installation. Existing VORP Stables 1.3 rows and IDs are preserved.
CREATE TABLE IF NOT EXISTS `stables` (
 `id` int NOT NULL AUTO_INCREMENT,
 `identifier` varchar(50) DEFAULT NULL,
 `charidentifier` int NOT NULL,
 `name` varchar(30) NOT NULL,
 `modelname` varchar(70) NOT NULL,
 `type` varchar(11) NOT NULL,
 `status` longtext DEFAULT NULL,
 `xp` int DEFAULT 0,
 `injured` int DEFAULT 0,
 `gear` longtext DEFAULT NULL,
 `isDefault` int NOT NULL DEFAULT 0,
 `inventory` longtext DEFAULT NULL,
 PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `horse_complements` (
 `identifier` varchar(50) DEFAULT NULL,
 `charidentifier` int NOT NULL,
 `complements` longtext NOT NULL,
 UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
