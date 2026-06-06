CREATE OR REPLACE FUNCTION check_and_update_seats_func()
RETURNS TRIGGER AS $$
DECLARE
    seats_count INT;
    sched_name VARCHAR(50);
END_DECLARATION;
BEGIN
    SELECT schedule_number_of_seats, schedule_name 
    INTO seats_count, sched_name
    FROM schedule 
    WHERE schedule_id = NEW.schedule_id;


    IF seats_count <= 0 THEN
        RAISE EXCEPTION 'Ошибка: На занятие "%" нет свободных мест!', sched_name;
    END IF;

    UPDATE schedule
    SET schedule_number_of_seats = schedule_number_of_seats - 1
    WHERE schedule_id = NEW.schedule_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_seats_trigger
BEFORE INSERT ON participates
FOR EACH ROW
EXECUTE FUNCTION check_and_update_seats_func();