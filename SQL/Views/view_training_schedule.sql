CREATE OR REPLACE VIEW view_training_schedule AS
SELECT 
    r.registration_date AS "Дата",
    r.registration_time AS "Время",
    i.instructor_full_name AS "Тренер",
    c.client_full_name AS "Клиент",
    'Персональная' AS "Тип тренировки",
    CASE WHEN r.registration_status THEN 'Проведена' ELSE 'Отменена' END AS "Статус"
FROM registration r
JOIN instructor i ON r.instructor_number = i.instructor_number
JOIN client c ON r.client_id = c.client_id
UNION ALL
SELECT 
    s.schedule_time::date AS "Дата",
    s.schedule_time::time AS "Время", 
    i.instructor_full_name AS "Тренер",
    s.schedule_name AS "Клиент",
    s.schedule_type AS "Тип тренировки",
    'В ожидании' AS "Статус"
FROM schedule s
JOIN instructor i ON s.instructor_number = i.instructor_number;