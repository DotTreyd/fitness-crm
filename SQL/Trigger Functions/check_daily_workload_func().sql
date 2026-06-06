CREATE OR REPLACE FUNCTION check_daily_workload_func()
RETURNS TRIGGER AS $$
DECLARE
    classes_today_count INT;
BEGIN
    SELECT COUNT(*) INTO classes_today_count
    FROM schedule s
    WHERE s.instructor_number = NEW.instructor_number
      AND s.schedule_time::date = NEW.schedule_time::date 
      AND s.schedule_id <> NEW.schedule_id;

    IF NEW.schedule_type = 'Групповая' AND classes_today_count >= 1 THEN
        RAISE EXCEPTION 'Перегрузка: Инструктор (ID=%) уже ведет групповую тренировку в этот день.', NEW.instructor_number;
    END IF;

    IF NEW.schedule_type = 'Персональная' AND classes_today_count >= 3 THEN
        RAISE EXCEPTION 'Перегрузка: Инструктор (ID=%) не может вести более 3 персональных тренировок.', NEW.instructor_number;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_instructor_workload_trigger
BEFORE INSERT OR UPDATE ON schedule
FOR EACH ROW
EXECUTE FUNCTION check_daily_workload_func();