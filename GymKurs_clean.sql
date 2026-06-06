--
-- PostgreSQL database dump
--


-- Dumped from database version 15.14
-- Dumped by pg_dump version 18.0

-- Started on 2026-05-20 22:33:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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

    RAISE NOTICE 'РћС‚РјРµРЅР° Р·Р°РЅСЏС‚РёСЏ "%". Р‘СѓРґРµС‚ РєРѕРјРїРµРЅСЃРёСЂРѕРІР°РЅРѕ % РєР»РёРµРЅС‚РѕРІ.', v_old_name, v_client_count;

    UPDATE schedule
    SET schedule_name = CONCAT('РћРўРњР•РќРђ: ', schedule_name),
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
        RAISE EXCEPTION 'РћС€РёР±РєР°: РќР° Р·Р°РЅСЏС‚РёРµ "%" РЅРµС‚ СЃРІРѕР±РѕРґРЅС‹С… РјРµСЃС‚!', sched_name;
    END IF;

    -- СѓРјРµРЅСЊС€Р°РµРј РєРѕР»-РІРѕ РјРµСЃС‚
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

    IF NEW.schedule_type = 'Р“СЂСѓРїРїРѕРІР°СЏ' AND classes_today_count >= 1 THEN
        RAISE EXCEPTION 'РџРµСЂРµРіСЂСѓР·РєР°: РРЅСЃС‚СЂСѓРєС‚РѕСЂ (ID=%) СѓР¶Рµ Р·Р°РЅСЏС‚ РІ СЌС‚РѕС‚ РґРµРЅСЊ. Р“СЂСѓРїРїРѕРІСѓСЋ С‚СЂРµРЅРёСЂРѕРІРєСѓ РјРѕР¶РЅРѕ СЃС‚Р°РІРёС‚СЊ С‚РѕР»СЊРєРѕ РѕРґРЅСѓ РІ РґРµРЅСЊ.', 
                        NEW.instructor_number;
    END IF;


    IF NEW.schedule_type = 'РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ' AND classes_today_count >= 3 THEN
        RAISE EXCEPTION 'РџРµСЂРµРіСЂСѓР·РєР°: РРЅСЃС‚СЂСѓРєС‚РѕСЂ (ID=%) РЅРµ РјРѕР¶РµС‚ РІРµСЃС‚Рё Р±РѕР»РµРµ 3 РїРµСЂСЃРѕРЅР°Р»СЊРЅС‹С… С‚СЂРµРЅРёСЂРѕРІРѕРє РІ РґРµРЅСЊ.', 
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

COPY public.additional_services (additional_services_id, additional_services_type) FROM stdin;
1	Р‘Р°СЃСЃРµР№РЅ
2	Р‘Р°РЅСЏ
3	РЎРѕР»СЏСЂРёР№
4	Р¤РёС‚РѕР±Р°СЂ
\.


--
-- TOC entry 3442 (class 0 OID 16471)
-- Dependencies: 217
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin (admin_full_name, admin_email, admin_id, admin_phone_number) FROM stdin;
РђРґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂ Р“Р»Р°РІРЅС‹Р№	admin@gym.ru	1	89990000000
РЎРјРёСЂРЅРѕРІР° Р•Р»РµРЅР° РџРµС‚СЂРѕРІРЅР°	smirnova@gym.ru	2	89001112233
РЎРѕРєРѕР»РѕРІР° РђРЅРЅР° Р”РјРёС‚СЂРёРµРІРЅР°	sokolova@gym.ru	3	89007778899
РљРѕР·Р»РѕРІ Р”РјРёС‚СЂРёР№ РћР»РµРіРѕРІРёС‡	kozlov@gym.ru	4	89001234567
\.


--
-- TOC entry 3444 (class 0 OID 16479)
-- Dependencies: 219
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (client_registration_date, client_id, admin_id, client_birthday, client_contacts, client_full_name) FROM stdin;
2024-02-15	2	1	1995-05-05	petrov@mail.ru	РџРµС‚СЂРѕРІ РђР»РµРєСЃРµР№ РђР»РµРєСЃР°РЅРґСЂРѕРІРёС‡
2024-09-10	7	4	1992-04-14	roman@gym.ru	Р—Р°Р№С†РµРІ Р РѕРјР°РЅ РђРЅРґСЂРµРµРІРёС‡
2025-02-20	10	2	2001-09-09	yana@bk.ru	РќРѕРІРёРєРѕРІР° РЇРЅР° Р•РІРіРµРЅСЊРµРІРЅР°
2025-10-08	11	1	1998-05-15	sokolov@mail.ru, 89005554433	РЎРѕРєРѕР»РѕРІ Р”РµРЅРёСЃ РџРµС‚СЂРѕРІРёС‡
2024-05-01	4	4	1998-12-12	olga@bk.ru	РЎРёРґРѕСЂРѕРІР° РћР»СЊРіР° Р’Р»Р°РґРёРјРёСЂРѕРІРЅР°
2024-06-15	5	4	1980-07-07	viktor@ya.ru	РњРѕСЂРѕР·РѕРІ Р’РёРєС‚РѕСЂ РЎРµСЂРіРµРµРІРёС‡
2024-01-10	1	4	1990-01-01	ivanov_new@mail.ru, +79001112233	РРІР°РЅРѕРІ РРІР°РЅ РРІР°РЅРѕРІРёС‡
2024-03-20	3	4	1985-10-10	kuznetsov@mail.ru [Р—Р°Р±Р»РѕРєРёСЂРѕРІР°РЅ]	РљСѓР·РЅРµС†РѕРІ РљРёСЂРёР»Р» РљРѕРЅСЃС‚Р°РЅС‚РёРЅРѕРІРёС‡
2025-01-15	9	4	1988-03-03	grom@mail.ru	Р“СЂРѕРјРѕРІ РРіРѕСЂСЊ РњРёС…Р°Р№Р»РѕРІРёС‡
2024-08-01	6	2	2000-02-28	anna@gmail.com	Р›РµР±РµРґРµРІР° РђРЅРЅР° РџР°РІР»РѕРІРЅР°
2024-11-05	8	3	1999-11-11	julia@list.ru	Р’РѕР»РєРѕРІР° Р®Р»РёСЏ Р”РјРёС‚СЂРёРµРІРЅР°
\.


--
-- TOC entry 3445 (class 0 OID 16488)
-- Dependencies: 220
-- Data for Name: include; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.include (additional_services_id, visits_id) FROM stdin;
1	1
2	2
1	10
2	15
1	20
2	25
\.


--
-- TOC entry 3446 (class 0 OID 16496)
-- Dependencies: 221
-- Data for Name: instructor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instructor (instructor_number, instructor_specialization, instructor_full_name) FROM stdin;
201	РџРµСЂСЃРѕРЅР°Р»СЊРЅС‹Р№ С‚СЂРµРЅРµСЂ	РЎРјРёСЂРЅРѕРІ РђРЅРґСЂРµР№ РђР»РµРєСЃР°РЅРґСЂРѕРІРёС‡
202	РРЅСЃС‚СЂСѓРєС‚РѕСЂ РіСЂСѓРїРїРѕРІС‹С…	РљРѕР·Р»РѕРІ РРІР°РЅ Р’Р°СЃРёР»СЊРµРІРёС‡
203	Р”РµР¶СѓСЂРЅС‹Р№ С‚СЂРµРЅРµСЂ	Р’РѕР»РєРѕРІР° РњР°СЂРёСЏ РРІР°РЅРѕРІРЅР°
304	РўСЂРµРЅРµСЂ Р±Р°СЃСЃРµР№РЅР°	РЁРІР°СЂС† РђСЂРЅРѕР»СЊРґ Р“СѓСЃС‚Р°РІРѕРІРёС‡
\.


--
-- TOC entry 3447 (class 0 OID 16503)
-- Dependencies: 222
-- Data for Name: participates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participates (schedule_id, client_id) FROM stdin;
1	4
1	5
2	6
2	7
4	1
4	10
5	2
5	3
5	4
6	1
6	2
\.


--
-- TOC entry 3449 (class 0 OID 16512)
-- Dependencies: 224
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (payments_number, client_id, payments_date, payments_purpose, payments_amounts, payments_method) FROM stdin;
1	1	2025-10-01	РћРїР»Р°С‚Р°: РњРµСЃСЏС‡РЅС‹Р№	3000	РќР°Р»
2	2	2025-10-02	РћРїР»Р°С‚Р°: Р Р°Р·РѕРІС‹Р№	500	РљР°СЂС‚Р°
3	3	2025-10-03	РћРїР»Р°С‚Р°: Р“РѕРґРѕРІРѕР№	30000	РџРµСЂРµРІРѕРґ
4	4	2024-05-01	РћРїР»Р°С‚Р° РіРѕРґРѕРІРѕРіРѕ	20000	РљР°СЂС‚Р°
5	5	2024-06-15	РћРїР»Р°С‚Р° РїРѕР»РіРѕРґР°	12000	РќР°Р»
6	6	2024-08-01	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РљР°СЂС‚Р°
7	7	2024-09-10	РћРїР»Р°С‚Р° РїРѕР»РіРѕРґР°	12000	QR-РєРѕРґ
8	1	2024-01-10	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РќР°Р»
9	1	2024-02-10	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РќР°Р»
10	2	2024-03-15	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РљР°СЂС‚Р°
11	8	2025-01-10	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3500	РљР°СЂС‚Р°
12	9	2025-01-15	РћРїР»Р°С‚Р° РіРѕРґРѕРІРѕРіРѕ	25000	РџРµСЂРµРІРѕРґ
13	10	2025-02-20	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РќР°Р»
14	6	2025-03-01	РћРїР»Р°С‚Р° РїРѕР»РіРѕРґР°	12500	РљР°СЂС‚Р°
15	5	2025-04-01	РџСЂРѕРґР»РµРЅРёРµ	10000	РќР°Р»
16	4	2025-05-01	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ С‚СЂРµРЅРёСЂРѕРІРєР°	2000	РљР°СЂС‚Р°
17	1	2025-06-01	РћРїР»Р°С‚Р° РїРѕР»РіРѕРґР°	12000	РќР°Р»
18	7	2025-07-01	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РљР°СЂС‚Р°
19	8	2025-08-01	РћРїР»Р°С‚Р° РјРµСЃСЏС†	3000	РљР°СЂС‚Р°
20	2	2025-09-01	Р Р°Р·РѕРІРѕРµ	500	РќР°Р»
21	3	2024-03-20	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ С‚СЂРµРЅРёСЂРѕРІРєР°	2500	РљР°СЂС‚Р°
22	9	2025-05-05	РўСЂРµРЅРёСЂРѕРІРєРё Р±Р»РѕРє	10000	РљР°СЂС‚Р°
23	10	2025-06-06	Р Р°Р·РѕРІРѕРµ	500	РќР°Р»
24	5	2025-07-07	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ С‚СЂРµРЅРёСЂРѕРІРєР°	2000	РљР°СЂС‚Р°
25	1	2025-09-15	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ С‚СЂРµРЅРёСЂРѕРІРєР°	2000	РќР°Р»
\.


--
-- TOC entry 3451 (class 0 OID 16521)
-- Dependencies: 226
-- Data for Name: registration; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.registration (registration_id, instructor_number, client_id, registration_status, registration_time, registration_date) FROM stdin;
1	201	1	t	10:00:00	2025-10-01
3	201	3	t	14:00:00	2025-10-05
4	304	4	t	18:00:00	2025-10-06
5	203	5	t	09:00:00	2025-10-07
7	304	7	t	19:00:00	2025-10-10
8	203	8	t	10:00:00	2025-10-12
11	201	1	t	10:00:00	2025-01-15
12	201	1	t	10:00:00	2025-02-15
13	201	1	t	10:00:00	2025-03-15
14	304	4	t	18:30:00	2025-05-01
15	304	4	t	18:30:00	2025-05-03
16	203	5	t	09:00:00	2025-06-10
17	203	5	f	09:00:00	2025-06-12
18	201	2	t	12:00:00	2025-07-20
19	201	2	t	12:00:00	2025-07-22
20	304	7	t	19:00:00	2025-09-01
21	304	7	t	19:00:00	2025-09-05
22	203	8	t	10:00:00	2025-09-10
23	203	8	t	10:00:00	2025-09-12
24	201	9	t	16:00:00	2025-09-15
25	201	3	t	14:00:00	2025-09-20
9	201	9	f	16:00:00	2025-10-15
27	201	1	f	14:25:00	2026-01-12
28	304	11	f	14:25:00	2026-05-20
\.


--
-- TOC entry 3453 (class 0 OID 16532)
-- Dependencies: 228
-- Data for Name: schedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_id, admin_id, instructor_number, schedule_type) FROM stdin;
Р“СЂСѓРїРїР° В«Р™РѕРіР°В»	2025-10-02	20	1	1	202	Р“СЂСѓРїРїРѕРІР°СЏ
Р Р°СЃС‚СЏР¶РєР° РЈС‚СЂРѕ	2025-10-05	15	2	2	203	Р“СЂСѓРїРїРѕРІР°СЏ
РџР»Р°РІР°РЅРёРµ РїСЂРѕС„Рё	2025-10-08	20	4	1	304	Р“СЂСѓРїРїРѕРІР°СЏ
Р—РґРѕСЂРѕРІР°СЏ СЃРїРёРЅР°	2025-10-10	20	5	4	203	Р“СЂСѓРїРїРѕРІР°СЏ
РџР°СЂРЅР°СЏ Р™РѕРіР°	2025-12-30	0	6	1	202	Р“СЂСѓРїРїРѕРІРѕРµ
РџРµСЂСЃРѕРЅР°Р»СЊРЅС‹Р№ Р±Р°СЃСЃРµР№РЅ	2025-10-11	1	10	1	304	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ
РџРµСЂСЃРѕРЅР°Р»СЊРЅС‹Р№ Р±Р°СЃСЃРµР№РЅ	2025-10-11	1	11	1	304	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ
РџРµСЂСЃРѕРЅР°Р»СЊРЅС‹Р№ Р±Р°СЃСЃРµР№РЅ	2025-10-11	1	12	1	304	РџРµСЂСЃРѕРЅР°Р»СЊРЅР°СЏ
РћРўРњР•РќРђ: РђРєРІР°Р°СЌСЂРѕР±РёРєР°	2025-10-06	0	3	3	304	Р“СЂСѓРїРїРѕРІР°СЏ
РћРўРњР•РќРђ: РЈС‚СЂРµРЅРЅРёРє	2026-01-08	0	14	1	203	Р“СЂСѓРїРїРѕРІР°СЏ
РћРўРњР•РќРђ: Р—РґРѕСЂРѕРІР°СЏ СЃРїРёРЅР°	2025-12-29	0	9	1	203	Р“СЂСѓРїРїРѕРІР°СЏ
РљРњР‘	2026-01-09	10	16	1	304	Р“СЂСѓРїРїРѕРІР°СЏ
РћРўРњР•РќРђ: Р‘РѕРєСЃ РЅР°С‡Р°Р»СЊРЅС‹Р№	2026-01-16	0	15	1	201	Р“СЂСѓРїРїРѕРІР°СЏ
Р‘Р°СЃСЃРµР№РЅ	2026-01-09	10	17	1	201	Р“СЂСѓРїРїРѕРІР°СЏ
\.


--
-- TOC entry 3455 (class 0 OID 16542)
-- Dependencies: 230
-- Data for Name: subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscription (subscription_id, admin_id, client_id, subscription_type, subscription_price, subscription_period, subscription_status) FROM stdin;
4	2	4	Р“РѕРґРѕРІРѕР№	20000	365	t
5	3	5	РџРѕР»РіРѕРґР°	12000	180	t
7	4	7	РџРѕР»РіРѕРґР°	12000	180	t
10	2	10	РњРµСЃСЏС‡РЅС‹Р№	3000	40	t
14	3	4	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
15	4	5	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
18	1	7	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
19	4	8	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
20	2	8	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
22	2	10	Р Р°Р·РѕРІС‹Р№	500	1	f
24	4	5	Р“РѕРґРѕРІРѕР№	18000	365	f
25	1	4	РџРѕР»РіРѕРґР°	11000	180	f
27	1	10	Р‘РѕРЅСѓСЃ	0	7	t
28	1	11	Р‘РѕРЅСѓСЃ	0	7	t
1	1	1	РњРµСЃСЏС‡РЅС‹Р№	3000	40	t
2	1	2	Р Р°Р·РѕРІС‹Р№	500	1	f
6	2	6	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
11	1	1	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
12	1	1	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
13	2	2	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
16	2	6	РџРѕР»РіРѕРґР°	12000	180	f
17	3	6	РњРµСЃСЏС‡РЅС‹Р№	3000	40	f
21	1	9	Р Р°Р·РѕРІС‹Р№	500	1	f
23	3	1	РџРѕР»РіРѕРґР°	12000	180	f
3	1	3	Р“РѕРґРѕРІРѕР№	30000	365	t
8	3	8	РњРµСЃСЏС‡РЅС‹Р№	3500	42	t
26	1	9	Р‘РѕРЅСѓСЃ	0	9	t
9	1	9	Р“РѕРґРѕРІРѕР№	25000	367	t
\.


--
-- TOC entry 3457 (class 0 OID 16554)
-- Dependencies: 232
-- Data for Name: visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visits (visits_marker, visits_time, visit_date, visits_id, client_id) FROM stdin;
t	10:13:00	2025-10-01	1	1
t	18:45:00	2025-10-02	2	2
t	14:00:00	2025-10-03	3	3
t	18:00:00	2025-10-04	4	4
t	09:05:00	2025-10-05	5	5
t	11:00:00	2025-10-05	6	6
t	19:10:00	2025-10-06	7	7
t	10:00:00	2025-10-06	8	8
t	16:15:00	2025-10-07	9	9
t	17:00:00	2025-10-07	10	10
t	10:10:00	2025-09-01	11	1
t	10:15:00	2025-09-03	12	1
t	10:12:00	2025-09-05	13	1
t	18:40:00	2025-09-10	14	2
t	18:50:00	2025-09-12	15	2
t	18:00:00	2025-09-15	16	4
t	18:00:00	2025-09-17	17	4
t	09:00:00	2025-09-20	18	5
t	09:00:00	2025-09-22	19	5
t	11:00:00	2025-09-25	20	6
t	19:00:00	2025-09-26	21	7
t	10:00:00	2025-09-27	22	8
t	16:00:00	2025-09-28	23	9
t	17:00:00	2025-09-29	24	10
t	14:00:00	2025-09-30	25	3
t	10:00:00	2025-09-08	26	1
t	19:11:49.909802	2025-12-21	27	1
\.


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


