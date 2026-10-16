-- READ ONLY preflight. Run on a backed-up staging database first.
-- Missing columns / errors mean stop and resolve the schema; do not blindly ALTER.
SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('stables','horse_complements')
ORDER BY TABLE_NAME,ORDINAL_POSITION;

SELECT COUNT(*) AS ownership_rows FROM stables;
SELECT COUNT(*) AS equipment_rows FROM horse_complements;
SELECT COUNT(*) AS unsupported_types FROM stables WHERE type NOT IN ('horse','cart');
SELECT COUNT(*) AS invalid_gear_json FROM stables WHERE gear IS NOT NULL AND gear<>'' AND NOT JSON_VALID(gear);
SELECT COUNT(*) AS invalid_status_json FROM stables WHERE status IS NOT NULL AND status<>'' AND NOT JSON_VALID(status);
SELECT COUNT(*) AS invalid_equipment_json FROM horse_complements WHERE NOT JSON_VALID(complements);

SELECT charidentifier,type,COUNT(*) AS active_count FROM stables
WHERE isDefault=1 GROUP BY charidentifier,type HAVING COUNT(*)>1;

-- These legacy bags need explicit manual mapping; do not duplicate their contents.
SELECT charidentifier,modelname,COUNT(*) AS owned_same_model FROM stables
GROUP BY charidentifier,modelname HAVING COUNT(*)>1;

SELECT charidentifier,COUNT(*) AS collection_count FROM horse_complements
GROUP BY charidentifier HAVING COUNT(*)>1;
