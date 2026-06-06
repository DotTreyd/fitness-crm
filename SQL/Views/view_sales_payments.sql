CREATE OR REPLACE VIEW view_sales_payments AS
SELECT 
    p.payments_date::date AS "Дата",
    p.payments_number AS "№ платежа",
    c.client_full_name AS "Клиент",
    s.subscription_type AS "Тип абонемента",
    p.payments_amounts AS "Сумма",
    p.payments_method AS "Способ",
    CASE WHEN s.subscription_status = TRUE THEN 'Активен' ELSE 'Истёк' END AS "Статус"
FROM payments p
JOIN client c ON p.client_id = c.client_id
JOIN subscription s ON c.client_id = s.client_id;