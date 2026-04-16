-- TabGis — Funções e Triggers para gestão de ordens (order_code, tarefas, reclamações)
-- Este ficheiro contém apenas as definições de funções e triggers que já foram aplicadas
-- e não devem ser re-executadas em cada migração, a menos que haja alteração explícita.

-- Contador diário para order_code = YYYYMMDD + 4 dígitos (reinicia à meia-noite no fuso SP)
CREATE TABLE IF NOT EXISTS operations.order_code_counter (
    day DATE PRIMARY KEY,
    seq INTEGER NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION operations.generate_work_order_code()
RETURNS TEXT AS $$
DECLARE
    d DATE := (CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date;
    n INTEGER;
BEGIN
    INSERT INTO operations.order_code_counter (day, seq)
    VALUES (d, 1)
    ON CONFLICT (day) DO UPDATE
    SET seq = operations.order_code_counter.seq + 1
    RETURNING seq INTO n;
    RETURN to_char(d, 'YYYYMMDD') || lpad(n::text, 4, '0');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION operations.work_order_before_insert_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.order_code IS NULL OR btrim(NEW.order_code) = '' THEN
        NEW.order_code := operations.generate_work_order_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_work_order_code ON operations.work_order;
CREATE TRIGGER trg_work_order_code
    BEFORE INSERT ON operations.work_order
    FOR EACH ROW
    EXECUTE FUNCTION operations.work_order_before_insert_code();

CREATE OR REPLACE FUNCTION operations.work_order_refresh_complaint_count()
RETURNS TRIGGER AS $$
DECLARE
    wid INTEGER;
BEGIN
    wid := COALESCE(NEW.work_order_id, OLD.work_order_id);
    UPDATE operations.work_order
    SET complaints_linked_count = (SELECT COUNT(*)::int FROM operations.work_order_complaint c WHERE c.work_order_id = wid),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = wid;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_complaint_count_ins ON operations.work_order_complaint;
CREATE TRIGGER trg_complaint_count_ins
    AFTER INSERT ON operations.work_order_complaint
    FOR EACH ROW
    EXECUTE FUNCTION operations.work_order_refresh_complaint_count();

DROP TRIGGER IF EXISTS trg_complaint_count_del ON operations.work_order_complaint;
CREATE TRIGGER trg_complaint_count_del
    AFTER DELETE ON operations.work_order_complaint
    FOR EACH ROW
    EXECUTE FUNCTION operations.work_order_refresh_complaint_count();

-- Arquivo antes de DELETE
DROP TRIGGER IF EXISTS trg_wo_task_archive_delete ON operations.work_order_task;
CREATE TRIGGER trg_wo_task_archive_delete
    BEFORE DELETE ON operations.work_order_task
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();

DROP TRIGGER IF EXISTS trg_wo_complaint_archive_delete ON operations.work_order_complaint;
CREATE TRIGGER trg_wo_complaint_archive_delete
    BEFORE DELETE ON operations.work_order_complaint
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();