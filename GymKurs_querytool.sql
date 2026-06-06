--
-- PostgreSQL database dump
--


-- Dumped from database version 15.14
-- Dumped by pg_dump version 18.0

-- Started on 2026-05-20 22:33:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 246 (class 1255 OID 41081)
-- Name: cancel_activity(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cancel_activity(IN p_schedule_id integer)
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

    RAISE NOTICE 'Отмена занятия "%". Будет компенсировано % клиентов.', v_old_name, v_client_count;

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


ALTER PROCEDURE public.cancel_activity(IN p_schedule_id integer) OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 41074)
-- Name: check_and_update_seats_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_and_update_seats_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    seats_count DECIMAL(2);
    sched_name VARCHAR(50);
BEGIN

    SELECT schedule_number_of_seats, schedule_name 
    INTO seats_count, sched_name
    FROM schedule 
    WHERE schedule_id = NEW.schedule_id;

    IF seats_count <= 0 THEN
        RAISE EXCEPTION 'Ошибка: На занятие "%" нет свободных мест!', sched_name;
    END IF;

    -- уменьшаем кол-во мест
    UPDATE schedule
    SET schedule_number_of_seats = schedule_number_of_seats - 1
    WHERE schedule_id = NEW.schedule_id;

    RETURN NEW;
END;$$;


ALTER FUNCTION public.check_and_update_seats_func() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 41079)
-- Name: check_daily_workload_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_daily_workload_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    classes_today_count INT;
BEGIN
    SELECT COUNT(*) INTO classes_today_count
    FROM schedule s
    WHERE s.instructor_number = NEW.instructor_number
      AND s.schedule_time = NEW.schedule_time 
      AND s.schedule_id <> NEW.schedule_id;

    IF NEW.schedule_type = 'Групповая' AND classes_today_count >= 1 THEN
        RAISE EXCEPTION 'Перегрузка: Инструктор (ID=%) уже занят в этот день. Групповую тренировку можно ставить только одну в день.', 
                        NEW.instructor_number;
    END IF;


    IF NEW.schedule_type = 'Персональная' AND classes_today_count >= 3 THEN
        RAISE EXCEPTION 'Перегрузка: Инструктор (ID=%) не может вести более 3 персональных тренировок в день.', 
                        NEW.instructor_number;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_daily_workload_func() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 16463)
-- Name: additional_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.additional_services (
    additional_services_id integer NOT NULL,
    additional_services_type character varying(15) NOT NULL
);


ALTER TABLE public.additional_services OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16462)
-- Name: additional_services_additional_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.additional_services_additional_services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.additional_services_additional_services_id_seq OWNER TO postgres;

--
-- TOC entry 3463 (class 0 OID 0)
-- Dependencies: 214
-- Name: additional_services_additional_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.additional_services_additional_services_id_seq OWNED BY public.additional_services.additional_services_id;


--
-- TOC entry 217 (class 1259 OID 16471)
-- Name: admin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin (
    admin_full_name character varying(50) NOT NULL,
    admin_email character varying(50) NOT NULL,
    admin_id integer NOT NULL,
    admin_phone_number character(11) NOT NULL
);


ALTER TABLE public.admin OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16470)
-- Name: admin_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_admin_id_seq OWNER TO postgres;

--
-- TOC entry 3464 (class 0 OID 0)
-- Dependencies: 216
-- Name: admin_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_admin_id_seq OWNED BY public.admin.admin_id;


--
-- TOC entry 219 (class 1259 OID 16479)
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    client_registration_date date NOT NULL,
    client_id integer NOT NULL,
    admin_id integer NOT NULL,
    client_birthday date NOT NULL,
    client_contacts character varying(100) NOT NULL,
    client_full_name character varying(50) NOT NULL
);


ALTER TABLE public.client OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16478)
-- Name: client_client_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.client_client_id_seq OWNER TO postgres;

--
-- TOC entry 3465 (class 0 OID 0)
-- Dependencies: 218
-- Name: client_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_client_id_seq OWNED BY public.client.client_id;


--
-- TOC entry 220 (class 1259 OID 16488)
-- Name: include; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.include (
    additional_services_id integer NOT NULL,
    visits_id integer NOT NULL
);


ALTER TABLE public.include OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16496)
-- Name: instructor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instructor (
    instructor_number numeric(10,0) NOT NULL,
    instructor_specialization character varying(50) NOT NULL,
    instructor_full_name character varying(50) NOT NULL
);


ALTER TABLE public.instructor OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16503)
-- Name: participates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participates (
    schedule_id integer NOT NULL,
    client_id integer NOT NULL
);


ALTER TABLE public.participates OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16512)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    payments_number integer NOT NULL,
    client_id integer NOT NULL,
    payments_date date NOT NULL,
    payments_purpose character varying(100) NOT NULL,
    payments_amounts numeric(6,0) NOT NULL,
    payments_method character varying(10) NOT NULL
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16511)
-- Name: payments_payments_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_payments_number_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_payments_number_seq OWNER TO postgres;

--
-- TOC entry 3466 (class 0 OID 0)
-- Dependencies: 223
-- Name: payments_payments_number_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_payments_number_seq OWNED BY public.payments.payments_number;


--
-- TOC entry 226 (class 1259 OID 16521)
-- Name: registration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registration (
    registration_id integer NOT NULL,
    instructor_number numeric(10,0) NOT NULL,
    client_id integer,
    registration_status boolean NOT NULL,
    registration_time time without time zone NOT NULL,
    registration_date date NOT NULL,
    registration_timestamp timestamp without time zone GENERATED ALWAYS AS ((registration_date + registration_time)) STORED
);


ALTER TABLE public.registration OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16520)
-- Name: registration_registration_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registration_registration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.registration_registration_id_seq OWNER TO postgres;

--
-- TOC entry 3467 (class 0 OID 0)
-- Dependencies: 225
-- Name: registration_registration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registration_registration_id_seq OWNED BY public.registration.registration_id;


--
-- TOC entry 228 (class 1259 OID 16532)
-- Name: schedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule (
    schedule_name character varying(50) NOT NULL,
    schedule_time date NOT NULL,
    schedule_number_of_seats numeric(2,0) NOT NULL,
    schedule_id integer NOT NULL,
    admin_id integer NOT NULL,
    instructor_number numeric(10,0) NOT NULL,
    schedule_type character varying(15) NOT NULL
);


ALTER TABLE public.schedule OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16531)
-- Name: schedule_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schedule_schedule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schedule_schedule_id_seq OWNER TO postgres;

--
-- TOC entry 3468 (class 0 OID 0)
-- Dependencies: 227
-- Name: schedule_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schedule_schedule_id_seq OWNED BY public.schedule.schedule_id;


--
-- TOC entry 230 (class 1259 OID 16542)
-- Name: subscription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription (
    subscription_id integer NOT NULL,
    admin_id integer NOT NULL,
    client_id integer NOT NULL,
    subscription_type character varying(10) NOT NULL,
    subscription_price numeric(6,0) NOT NULL,
    subscription_period numeric(3,0) NOT NULL,
    subscription_status boolean NOT NULL,
    subscription_discount_price numeric(8,2) GENERATED ALWAYS AS ((subscription_price * 0.85)) STORED
);


ALTER TABLE public.subscription OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16541)
-- Name: subscription_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscription_subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscription_subscription_id_seq OWNER TO postgres;

--
-- TOC entry 3469 (class 0 OID 0)
-- Dependencies: 229
-- Name: subscription_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscription_subscription_id_seq OWNED BY public.subscription.subscription_id;


--
-- TOC entry 232 (class 1259 OID 16554)
-- Name: visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visits (
    visits_marker boolean NOT NULL,
    visits_time time without time zone,
    visit_date date NOT NULL,
    visits_id integer NOT NULL,
    client_id integer NOT NULL
);


ALTER TABLE public.visits OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16553)
-- Name: visits_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visits_visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visits_visits_id_seq OWNER TO postgres;

--
-- TOC entry 3470 (class 0 OID 0)
-- Dependencies: 231
-- Name: visits_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visits_visits_id_seq OWNED BY public.visits.visits_id;


--
-- TOC entry 3223 (class 2604 OID 16466)
-- Name: additional_services additional_services_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.additional_services ALTER COLUMN additional_services_id SET DEFAULT nextval('public.additional_services_additional_services_id_seq'::regclass);


--
-- TOC entry 3224 (class 2604 OID 16474)
-- Name: admin admin_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin ALTER COLUMN admin_id SET DEFAULT nextval('public.admin_admin_id_seq'::regclass);


--
-- TOC entry 3225 (class 2604 OID 16482)
-- Name: client client_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client ALTER COLUMN client_id SET DEFAULT nextval('public.client_client_id_seq'::regclass);


--
-- TOC entry 3226 (class 2604 OID 16515)
-- Name: payments payments_number; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN payments_number SET DEFAULT nextval('public.payments_payments_number_seq'::regclass);


--
-- TOC entry 3227 (class 2604 OID 16524)
-- Name: registration registration_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration ALTER COLUMN registration_id SET DEFAULT nextval('public.registration_registration_id_seq'::regclass);


--
-- TOC entry 3229 (class 2604 OID 16535)
-- Name: schedule schedule_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule ALTER COLUMN schedule_id SET DEFAULT nextval('public.schedule_schedule_id_seq'::regclass);


--
-- TOC entry 3230 (class 2604 OID 16545)
-- Name: subscription subscription_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscription_subscription_id_seq'::regclass);


--
-- TOC entry 3232 (class 2604 OID 16557)
-- Name: visits visits_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits ALTER COLUMN visits_id SET DEFAULT nextval('public.visits_visits_id_seq'::regclass);


--
-- TOC entry 3440 (class 0 OID 16463)
-- Dependencies: 215
-- Data for Name: additional_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.additional_services
BEGIN;
INSERT INTO public.additional_services (additional_services_id, additional_services_type) VALUES ('1', 'Бассейн');
INSERT INTO public.additional_services (additional_services_id, additional_services_type) VALUES ('2', 'Баня');
INSERT INTO public.additional_services (additional_services_id, additional_services_type) VALUES ('3', 'Солярий');
INSERT INTO public.additional_services (additional_services_id, additional_services_type) VALUES ('4', 'Фитобар');
COMMIT;


--
-- TOC entry 3442 (class 0 OID 16471)
-- Dependencies: 217
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.admin
BEGIN;
INSERT INTO public.admin (admin_full_name, admin_email, admin_id, admin_phone_number) VALUES ('Администратор Главный', 'admin@gym.ru', '1', '89990000000');
INSERT INTO public.admin (admin_full_name, admin_email, admin_id, admin_phone_number) VALUES ('Смирнова Елена Петровна', 'smirnova@gym.ru', '2', '89001112233');
INSERT INTO public.admin (admin_full_name, admin_email, admin_id, admin_phone_number) VALUES ('Соколова Анна Дмитриевна', 'sokolova@gym.ru', '3', '89007778899');
INSERT INTO public.admin (admin_full_name, admin_email, admin_id, admin_phone_number) VALUES ('Козлов Дмитрий Олегович', 'kozlov@gym.ru', '4', '89001234567');
COMMIT;


--
-- TOC entry 3444 (class 0 OID 16479)
-- Dependencies: 219
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.client
BEGIN;
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-02-15', '2', '1', '1995-05-05', 'petrov@mail.ru', 'Петров Алексей Александрович');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-09-10', '7', '4', '1992-04-14', 'roman@gym.ru', 'Зайцев Роман Андреевич');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2025-02-20', '10', '2', '2001-09-09', 'yana@bk.ru', 'Новикова Яна Евгеньевна');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2025-10-08', '11', '1', '1998-05-15', 'sokolov@mail.ru, 89005554433', 'Соколов Денис Петрович');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-05-01', '4', '4', '1998-12-12', 'olga@bk.ru', 'Сидорова Ольга Владимировна');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-06-15', '5', '4', '1980-07-07', 'viktor@ya.ru', 'Морозов Виктор Сергеевич');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-01-10', '1', '4', '1990-01-01', 'ivanov_new@mail.ru, +79001112233', 'Иванов Иван Иванович');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-03-20', '3', '4', '1985-10-10', 'kuznetsov@mail.ru [Заблокирован]', 'Кузнецов Кирилл Константинович');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2025-01-15', '9', '4', '1988-03-03', 'grom@mail.ru', 'Громов Игорь Михайлович');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-08-01', '6', '2', '2000-02-28', 'anna@gmail.com', 'Лебедева Анна Павловна');
INSERT INTO public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) VALUES ('2024-11-05', '8', '3', '1999-11-11', 'julia@list.ru', 'Волкова Юлия Дмитриевна');
COMMIT;


--
-- TOC entry 3445 (class 0 OID 16488)
-- Dependencies: 220
-- Data for Name: include; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.include
BEGIN;
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('1', '1');
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('2', '2');
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('1', '10');
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('2', '15');
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('1', '20');
INSERT INTO public.include (additional_services_id, visits_id) VALUES ('2', '25');
COMMIT;


--
-- TOC entry 3446 (class 0 OID 16496)
-- Dependencies: 221
-- Data for Name: instructor; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.instructor
BEGIN;
INSERT INTO public.instructor (instructor_number, instructor_specialization, instructor_full_name) VALUES ('201', 'Персональный тренер', 'Смирнов Андрей Александрович');
INSERT INTO public.instructor (instructor_number, instructor_specialization, instructor_full_name) VALUES ('202', 'Инструктор групповых', 'Козлов Иван Васильевич');
INSERT INTO public.instructor (instructor_number, instructor_specialization, instructor_full_name) VALUES ('203', 'Дежурный тренер', 'Волкова Мария Ивановна');
INSERT INTO public.instructor (instructor_number, instructor_specialization, instructor_full_name) VALUES ('304', 'Тренер бассейна', 'Шварц Арнольд Густавович');
COMMIT;


--
-- TOC entry 3447 (class 0 OID 16503)
-- Dependencies: 222
-- Data for Name: participates; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.participates
BEGIN;
INSERT INTO public.participates (schedule_id, client_id) VALUES ('1', '4');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('1', '5');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('2', '6');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('2', '7');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('4', '1');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('4', '10');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('5', '2');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('5', '3');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('5', '4');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('6', '1');
INSERT INTO public.participates (schedule_id, client_id) VALUES ('6', '2');
COMMIT;


--
-- TOC entry 3449 (class 0 OID 16512)
-- Dependencies: 224
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.payments
BEGIN;
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('1', '1', '2025-10-01', 'Оплата: Месячный', '3000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('2', '2', '2025-10-02', 'Оплата: Разовый', '500', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('3', '3', '2025-10-03', 'Оплата: Годовой', '30000', 'Перевод');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('4', '4', '2024-05-01', 'Оплата годового', '20000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('5', '5', '2024-06-15', 'Оплата полгода', '12000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('6', '6', '2024-08-01', 'Оплата месяц', '3000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('7', '7', '2024-09-10', 'Оплата полгода', '12000', 'QR-код');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('8', '1', '2024-01-10', 'Оплата месяц', '3000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('9', '1', '2024-02-10', 'Оплата месяц', '3000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('10', '2', '2024-03-15', 'Оплата месяц', '3000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('11', '8', '2025-01-10', 'Оплата месяц', '3500', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('12', '9', '2025-01-15', 'Оплата годового', '25000', 'Перевод');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('13', '10', '2025-02-20', 'Оплата месяц', '3000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('14', '6', '2025-03-01', 'Оплата полгода', '12500', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('15', '5', '2025-04-01', 'Продление', '10000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('16', '4', '2025-05-01', 'Персональная тренировка', '2000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('17', '1', '2025-06-01', 'Оплата полгода', '12000', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('18', '7', '2025-07-01', 'Оплата месяц', '3000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('19', '8', '2025-08-01', 'Оплата месяц', '3000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('20', '2', '2025-09-01', 'Разовое', '500', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('21', '3', '2024-03-20', 'Персональная тренировка', '2500', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('22', '9', '2025-05-05', 'Тренировки блок', '10000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('23', '10', '2025-06-06', 'Разовое', '500', 'Нал');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('24', '5', '2025-07-07', 'Персональная тренировка', '2000', 'Карта');
INSERT INTO public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) VALUES ('25', '1', '2025-09-15', 'Персональная тренировка', '2000', 'Нал');
COMMIT;


--
-- TOC entry 3451 (class 0 OID 16521)
-- Dependencies: 226
-- Data for Name: registration; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.registration
BEGIN;
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('1', '201', '1', 't', '10:00:00', '2025-10-01');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('3', '201', '3', 't', '14:00:00', '2025-10-05');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('4', '304', '4', 't', '18:00:00', '2025-10-06');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('5', '203', '5', 't', '09:00:00', '2025-10-07');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('7', '304', '7', 't', '19:00:00', '2025-10-10');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('8', '203', '8', 't', '10:00:00', '2025-10-12');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('11', '201', '1', 't', '10:00:00', '2025-01-15');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('12', '201', '1', 't', '10:00:00', '2025-02-15');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('13', '201', '1', 't', '10:00:00', '2025-03-15');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('14', '304', '4', 't', '18:30:00', '2025-05-01');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('15', '304', '4', 't', '18:30:00', '2025-05-03');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('16', '203', '5', 't', '09:00:00', '2025-06-10');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('17', '203', '5', 'f', '09:00:00', '2025-06-12');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('18', '201', '2', 't', '12:00:00', '2025-07-20');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('19', '201', '2', 't', '12:00:00', '2025-07-22');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('20', '304', '7', 't', '19:00:00', '2025-09-01');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('21', '304', '7', 't', '19:00:00', '2025-09-05');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('22', '203', '8', 't', '10:00:00', '2025-09-10');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('23', '203', '8', 't', '10:00:00', '2025-09-12');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('24', '201', '9', 't', '16:00:00', '2025-09-15');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('25', '201', '3', 't', '14:00:00', '2025-09-20');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('9', '201', '9', 'f', '16:00:00', '2025-10-15');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('27', '201', '1', 'f', '14:25:00', '2026-01-12');
INSERT INTO public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) VALUES ('28', '304', '11', 'f', '14:25:00', '2026-05-20');
COMMIT;


--
-- TOC entry 3453 (class 0 OID 16532)
-- Dependencies: 228
-- Data for Name: schedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.schedule
BEGIN;
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Группа «Йога»', '2025-10-02', '20', '1', '1', '202', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Растяжка Утро', '2025-10-05', '15', '2', '2', '203', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Плавание профи', '2025-10-08', '20', '4', '1', '304', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Здоровая спина', '2025-10-10', '20', '5', '4', '203', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Парная Йога', '2025-12-30', '0', '6', '1', '202', 'Групповое');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Персональный бассейн', '2025-10-11', '1', '10', '1', '304', 'Персональная');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Персональный бассейн', '2025-10-11', '1', '11', '1', '304', 'Персональная');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Персональный бассейн', '2025-10-11', '1', '12', '1', '304', 'Персональная');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('ОТМЕНА: Аквааэробика', '2025-10-06', '0', '3', '3', '304', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('ОТМЕНА: Утренник', '2026-01-08', '0', '14', '1', '203', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('ОТМЕНА: Здоровая спина', '2025-12-29', '0', '9', '1', '203', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('КМБ', '2026-01-09', '10', '16', '1', '304', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('ОТМЕНА: Бокс начальный', '2026-01-16', '0', '15', '1', '201', 'Групповая');
INSERT INTO public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) VALUES ('Бассейн', '2026-01-09', '10', '17', '1', '201', 'Групповая');
COMMIT;


--
-- TOC entry 3455 (class 0 OID 16542)
-- Dependencies: 230
-- Data for Name: subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.subscription
BEGIN;
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('4', '2', '4', 'Годовой', '20000', '365', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('5', '3', '5', 'Полгода', '12000', '180', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('7', '4', '7', 'Полгода', '12000', '180', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('10', '2', '10', 'Месячный', '3000', '40', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('14', '3', '4', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('15', '4', '5', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('18', '1', '7', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('19', '4', '8', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('20', '2', '8', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('22', '2', '10', 'Разовый', '500', '1', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('24', '4', '5', 'Годовой', '18000', '365', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('25', '1', '4', 'Полгода', '11000', '180', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('27', '1', '10', 'Бонус', '0', '7', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('28', '1', '11', 'Бонус', '0', '7', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('1', '1', '1', 'Месячный', '3000', '40', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('2', '1', '2', 'Разовый', '500', '1', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('6', '2', '6', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('11', '1', '1', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('12', '1', '1', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('13', '2', '2', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('16', '2', '6', 'Полгода', '12000', '180', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('17', '3', '6', 'Месячный', '3000', '40', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('21', '1', '9', 'Разовый', '500', '1', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('23', '3', '1', 'Полгода', '12000', '180', 'f');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('3', '1', '3', 'Годовой', '30000', '365', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('8', '3', '8', 'Месячный', '3500', '42', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('26', '1', '9', 'Бонус', '0', '9', 't');
INSERT INTO public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) VALUES ('9', '1', '9', 'Годовой', '25000', '367', 't');
COMMIT;


--
-- TOC entry 3457 (class 0 OID 16554)
-- Dependencies: 232
-- Data for Name: visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- Converted COPY for public.visits
BEGIN;
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:13:00', '2025-10-01', '1', '1');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:45:00', '2025-10-02', '2', '2');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '14:00:00', '2025-10-03', '3', '3');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:00:00', '2025-10-04', '4', '4');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '09:05:00', '2025-10-05', '5', '5');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '11:00:00', '2025-10-05', '6', '6');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '19:10:00', '2025-10-06', '7', '7');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:00:00', '2025-10-06', '8', '8');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '16:15:00', '2025-10-07', '9', '9');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '17:00:00', '2025-10-07', '10', '10');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:10:00', '2025-09-01', '11', '1');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:15:00', '2025-09-03', '12', '1');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:12:00', '2025-09-05', '13', '1');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:40:00', '2025-09-10', '14', '2');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:50:00', '2025-09-12', '15', '2');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:00:00', '2025-09-15', '16', '4');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '18:00:00', '2025-09-17', '17', '4');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '09:00:00', '2025-09-20', '18', '5');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '09:00:00', '2025-09-22', '19', '5');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '11:00:00', '2025-09-25', '20', '6');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '19:00:00', '2025-09-26', '21', '7');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:00:00', '2025-09-27', '22', '8');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '16:00:00', '2025-09-28', '23', '9');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '17:00:00', '2025-09-29', '24', '10');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '14:00:00', '2025-09-30', '25', '3');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '10:00:00', '2025-09-08', '26', '1');
INSERT INTO public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) VALUES ('t', '19:11:49.909802', '2025-12-21', '27', '1');
COMMIT;


--
-- TOC entry 3471 (class 0 OID 0)
-- Dependencies: 214
-- Name: additional_services_additional_services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.additional_services_additional_services_id_seq', 4, true);


--
-- TOC entry 3472 (class 0 OID 0)
-- Dependencies: 216
-- Name: admin_admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_admin_id_seq', 4, true);


--
-- TOC entry 3473 (class 0 OID 0)
-- Dependencies: 218
-- Name: client_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_client_id_seq', 11, true);


--
-- TOC entry 3474 (class 0 OID 0)
-- Dependencies: 223
-- Name: payments_payments_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_payments_number_seq', 25, true);


--
-- TOC entry 3475 (class 0 OID 0)
-- Dependencies: 225
-- Name: registration_registration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.registration_registration_id_seq', 28, true);


--
-- TOC entry 3476 (class 0 OID 0)
-- Dependencies: 227
-- Name: schedule_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schedule_schedule_id_seq', 17, true);


--
-- TOC entry 3477 (class 0 OID 0)
-- Dependencies: 229
-- Name: subscription_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscription_subscription_id_seq', 28, true);


--
-- TOC entry 3478 (class 0 OID 0)
-- Dependencies: 231
-- Name: visits_visits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visits_visits_id_seq', 27, true);


--
-- TOC entry 3235 (class 2606 OID 16468)
-- Name: additional_services pk_additional_services; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.additional_services
    ADD CONSTRAINT pk_additional_services PRIMARY KEY (additional_services_id);


--
-- TOC entry 3238 (class 2606 OID 16476)
-- Name: admin pk_admin; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT pk_admin PRIMARY KEY (admin_id);


--
-- TOC entry 3243 (class 2606 OID 16484)
-- Name: client pk_client; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT pk_client PRIMARY KEY (client_id);


--
-- TOC entry 3248 (class 2606 OID 16492)
-- Name: include pk_include; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.include
    ADD CONSTRAINT pk_include PRIMARY KEY (additional_services_id, visits_id);


--
-- TOC entry 3252 (class 2606 OID 16500)
-- Name: instructor pk_instructor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor
    ADD CONSTRAINT pk_instructor PRIMARY KEY (instructor_number);


--
-- TOC entry 3257 (class 2606 OID 16507)
-- Name: participates pk_participates; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participates
    ADD CONSTRAINT pk_participates PRIMARY KEY (schedule_id, client_id);


--
-- TOC entry 3261 (class 2606 OID 16517)
-- Name: payments pk_payments; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT pk_payments PRIMARY KEY (payments_number);


--
-- TOC entry 3264 (class 2606 OID 16527)
-- Name: registration pk_registration; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration
    ADD CONSTRAINT pk_registration PRIMARY KEY (registration_id);


--
-- TOC entry 3270 (class 2606 OID 16537)
-- Name: schedule pk_schedule; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule
    ADD CONSTRAINT pk_schedule PRIMARY KEY (schedule_id);


--
-- TOC entry 3275 (class 2606 OID 16548)
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (subscription_id);


--
-- TOC entry 3280 (class 2606 OID 16559)
-- Name: visits pk_visits; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT pk_visits PRIMARY KEY (visits_id);


--
-- TOC entry 3233 (class 1259 OID 16469)
-- Name: additional_services_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX additional_services_pk ON public.additional_services USING btree (additional_services_id);


--
-- TOC entry 3239 (class 1259 OID 16486)
-- Name: adds_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adds_fk ON public.client USING btree (admin_id);


--
-- TOC entry 3236 (class 1259 OID 16477)
-- Name: admin_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX admin_pk ON public.admin USING btree (admin_id);


--
-- TOC entry 3240 (class 1259 OID 16485)
-- Name: client_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX client_pk ON public.client USING btree (client_id);


--
-- TOC entry 3262 (class 1259 OID 16530)
-- Name: conducts_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conducts_fk ON public.registration USING btree (instructor_number);


--
-- TOC entry 3267 (class 1259 OID 16540)
-- Name: controls_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX controls_fk ON public.schedule USING btree (admin_id);


--
-- TOC entry 3272 (class 1259 OID 16550)
-- Name: creates_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX creates_fk ON public.subscription USING btree (admin_id);


--
-- TOC entry 3273 (class 1259 OID 16552)
-- Name: idx_active_subs; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_active_subs ON public.subscription USING btree (subscription_status);


--
-- TOC entry 3241 (class 1259 OID 16487)
-- Name: idx_client_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_name ON public.client USING btree (client_full_name);


--
-- TOC entry 3249 (class 1259 OID 16502)
-- Name: idx_instructor_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_instructor_name ON public.instructor USING btree (instructor_full_name);


--
-- TOC entry 3244 (class 1259 OID 16495)
-- Name: include2_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX include2_fk ON public.include USING btree (visits_id);


--
-- TOC entry 3245 (class 1259 OID 16494)
-- Name: include_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX include_fk ON public.include USING btree (additional_services_id);


--
-- TOC entry 3246 (class 1259 OID 16493)
-- Name: include_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX include_pk ON public.include USING btree (additional_services_id, visits_id);


--
-- TOC entry 3250 (class 1259 OID 16501)
-- Name: instructor_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX instructor_pk ON public.instructor USING btree (instructor_number);


--
-- TOC entry 3278 (class 1259 OID 16561)
-- Name: is recorded_FK; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "is recorded_FK" ON public.visits USING btree (client_id);


--
-- TOC entry 3268 (class 1259 OID 16539)
-- Name: manages_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX manages_fk ON public.schedule USING btree (instructor_number);


--
-- TOC entry 3253 (class 1259 OID 16510)
-- Name: participates2_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX participates2_fk ON public.participates USING btree (client_id);


--
-- TOC entry 3254 (class 1259 OID 16509)
-- Name: participates_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX participates_fk ON public.participates USING btree (schedule_id);


--
-- TOC entry 3255 (class 1259 OID 16508)
-- Name: participates_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX participates_pk ON public.participates USING btree (schedule_id, client_id);


--
-- TOC entry 3258 (class 1259 OID 16518)
-- Name: payments_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX payments_pk ON public.payments USING btree (payments_number);


--
-- TOC entry 3259 (class 1259 OID 16519)
-- Name: pays_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pays_fk ON public.payments USING btree (client_id);


--
-- TOC entry 3276 (class 1259 OID 16551)
-- Name: purchases_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX purchases_fk ON public.subscription USING btree (client_id);


--
-- TOC entry 3265 (class 1259 OID 16528)
-- Name: registration_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX registration_pk ON public.registration USING btree (registration_id);


--
-- TOC entry 3271 (class 1259 OID 16538)
-- Name: schedule_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX schedule_pk ON public.schedule USING btree (schedule_id);


--
-- TOC entry 3277 (class 1259 OID 16549)
-- Name: subscription_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX subscription_pk ON public.subscription USING btree (subscription_id);


--
-- TOC entry 3266 (class 1259 OID 16529)
-- Name: undergoing_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX undergoing_fk ON public.registration USING btree (client_id);


--
-- TOC entry 3281 (class 1259 OID 16560)
-- Name: visits_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX visits_pk ON public.visits USING btree (visits_id);


--
-- TOC entry 3296 (class 2620 OID 41080)
-- Name: schedule trg_check_daily_load; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_daily_load BEFORE INSERT OR UPDATE ON public.schedule FOR EACH ROW EXECUTE FUNCTION public.check_daily_workload_func();


--
-- TOC entry 3295 (class 2620 OID 41075)
-- Name: participates trg_check_seats; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_seats BEFORE INSERT ON public.participates FOR EACH ROW EXECUTE FUNCTION public.check_and_update_seats_func();


--
-- TOC entry 3294 (class 2606 OID 16622)
-- Name: visits FK_VISITS_IS RECORD_CLIENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT "FK_VISITS_IS RECORD_CLIENT" FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3282 (class 2606 OID 16562)
-- Name: client fk_client_adds_admin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT fk_client_adds_admin FOREIGN KEY (admin_id) REFERENCES public.admin(admin_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3283 (class 2606 OID 16572)
-- Name: include fk_include_include2_visits; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.include
    ADD CONSTRAINT fk_include_include2_visits FOREIGN KEY (visits_id) REFERENCES public.visits(visits_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3284 (class 2606 OID 16567)
-- Name: include fk_include_include_addition; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.include
    ADD CONSTRAINT fk_include_include_addition FOREIGN KEY (additional_services_id) REFERENCES public.additional_services(additional_services_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3285 (class 2606 OID 16582)
-- Name: participates fk_particip_participa_client; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participates
    ADD CONSTRAINT fk_particip_participa_client FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 3286 (class 2606 OID 16577)
-- Name: participates fk_particip_participa_schedule; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participates
    ADD CONSTRAINT fk_particip_participa_schedule FOREIGN KEY (schedule_id) REFERENCES public.schedule(schedule_id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 3287 (class 2606 OID 16587)
-- Name: payments fk_payments_pays_client; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_pays_client FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3288 (class 2606 OID 16592)
-- Name: registration fk_registra_conducts_instruct; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration
    ADD CONSTRAINT fk_registra_conducts_instruct FOREIGN KEY (instructor_number) REFERENCES public.instructor(instructor_number) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3289 (class 2606 OID 16597)
-- Name: registration fk_registra_undergoin_client; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration
    ADD CONSTRAINT fk_registra_undergoin_client FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 3290 (class 2606 OID 16602)
-- Name: schedule fk_schedule_controls_admin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule
    ADD CONSTRAINT fk_schedule_controls_admin FOREIGN KEY (admin_id) REFERENCES public.admin(admin_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3291 (class 2606 OID 16607)
-- Name: schedule fk_schedule_manages_instruct; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule
    ADD CONSTRAINT fk_schedule_manages_instruct FOREIGN KEY (instructor_number) REFERENCES public.instructor(instructor_number) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3292 (class 2606 OID 16612)
-- Name: subscription fk_subscrip_creates_admin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT fk_subscrip_creates_admin FOREIGN KEY (admin_id) REFERENCES public.admin(admin_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3293 (class 2606 OID 16617)
-- Name: subscription fk_subscrip_purchases_client; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT fk_subscrip_purchases_client FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2026-05-20 22:33:17

--
-- PostgreSQL database dump complete
--


