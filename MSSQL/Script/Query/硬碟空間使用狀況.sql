WITH RowCounts AS (
    SELECT 
        t.object_id,
        MAX(p.rows) AS RowCounts
    FROM sys.tables t
    JOIN sys.indexes i ON t.object_id = i.object_id
    JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE i.index_id IN (0, 1) -- heap ©Î clustered index
    GROUP BY t.object_id
)
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    rc.RowCounts,
    CAST(ROUND(SUM(CASE WHEN i.index_id <= 1 THEN a.total_pages ELSE 0 END) * 8 / 1024.0, 2) AS NUMERIC(36, 2)) AS DataMB,
    CAST(ROUND(SUM(CASE WHEN i.index_id > 1 THEN a.total_pages ELSE 0 END) * 8 / 1024.0, 2) AS NUMERIC(36, 2)) AS IndexMB,
    CAST(ROUND(SUM(a.total_pages) * 8 / 1024.0, 2) AS NUMERIC(36, 2)) AS TotalMB
FROM 
    sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
JOIN RowCounts rc ON t.object_id = rc.object_id
WHERE 
    t.is_ms_shipped = 0
GROUP BY 
    s.name, t.name, rc.RowCounts
ORDER BY 
    TotalMB DESC;
