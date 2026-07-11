-- Rollback for 014_graph_receipt_projection

DROP TABLE IF EXISTS graph_receipts;
DELETE FROM _migrations WHERE name = '014_graph_receipt_projection';
