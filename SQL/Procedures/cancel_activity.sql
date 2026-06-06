CREATE OR REPLACE PROCEDURE cancel_activity(p_schedule_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_name VARCHAR(50);
    v_client_count INT;
BEGIN
    SELECT schedule_name, 
           (SELECT COUNT(*) FROM participates WHERE schedule_id = p_schedule_id)
    INTO v_old_name, v_client_count
    FROM schedule
    WHERE schedule_id = p_schedule_id;

    UPDATE schedule
    SET schedule_name = CONCAT('ОТМЕНА: ', schedule_name),
        schedule_number_of_seats = 0
    WHERE schedule_id = p_schedule_id;

    UPDATE subscription
    SET subscription_period = subscription_period + 2
    WHERE subscription_status = TRUE 
      AND client_id IN (
          SELECT client_id 
          FROM participates 
          WHERE schedule_id = p_schedule_id
      );

    DELETE FROM participates
    WHERE schedule_id = p_schedule_id;

    COMMIT;
END;
$$;