--
-- PostgreSQL database dump
--

-- Dumped from database version 14.1
-- Dumped by pg_dump version 15.6

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


CREATE DATABASE test;

--
-- Name: status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.status AS ENUM (
    'enrolled',
    'resigned',
    'graduate'
);


ALTER TYPE public.status OWNER TO postgres;

--
-- Name: check_enrollment(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_enrollment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Retrieve the degree ID from the exam table
    DECLARE
        exam_degree_id INTEGER;
 prop_course INTEGER;
 exam_to_check INTEGER;
    BEGIN
        SELECT DISTINCT c.degree INTO exam_degree_id
        FROM exam e
        JOIN course c ON e.course = c.id
        WHERE e.id = NEW.exam;

        IF (SELECT s.degree FROM student s WHERE s.id = NEW.student) <> exam_degree_id THEN
            RAISE EXCEPTION 'Student is not in the right degree for this exam';
        END IF;

 -- Check propedeutic course
 IF NOT EXISTS (
    SELECT DISTINCT propedeutic_course
        FROM exam e
    JOIN propedeucity p ON e.course = p.course
        WHERE e.id = NEW.exam
 ) THEN
   RETURN NEW;
 END IF;

 SELECT DISTINCT propedeutic_course INTO prop_course
     FROM exam e
 JOIN propedeucity p ON e.course = p.course
     WHERE e.id = NEW.exam;

 -- Find exam
 SELECT id INTO exam_to_check
 FROM exam WHERE course = prop_course;

     IF NOT EXISTS (
           SELECT mark
           FROM enrollment e
           JOIN exam ex on e.exam = ex.id
           WHERE e.exam = exam_to_check AND e.student = NEW.student
     ) THEN
         RAISE EXCEPTION 'Student does not respect propedeucity';
     END IF;

    END;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_enrollment() OWNER TO postgres;

--
-- Name: check_overlap(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Retrieve the degree ID from the exam table
    DECLARE
        exam_degree_id INTEGER;
	exam_year INTEGER;
    BEGIN
    -- From exam, find course and year
    SELECT degree, year
    INTO exam_degree_id, exam_year
    FROM exam e
    JOIN course c ON c.id = e.course
    WHERE c.id = NEW.course;
    
    -- From year and degree, list all the exams on the same year and degree
    IF EXISTS (
       SELECT e.id
       FROM exam e
       JOIN course c ON e.course = c.id
       JOIN degree d ON c.degree = d.id
       WHERE d.id = exam_degree_id AND c.year = exam_year and e.date = NEW.date
    ) THEN
      RAISE EXCEPTION 'Exam overlap with another exam';
    END IF;

    RETURN NEW;

    END;
END;
$$;


ALTER FUNCTION public.check_overlap() OWNER TO postgres;

--
-- Name: insert_account(character varying, character varying, character varying, character, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_account(name character varying, surname character varying, email character varying, password character, birthdate date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
 account_id INTEGER;
BEGIN
 INSERT INTO account(id, name, surname, email, password, birthdate) values(default, name, surname, email, password, birthdate) RETURNING id into account_id;
 INSERT INTO teacher values(account_id);

 RETURN account_id;
END;
$$;


ALTER FUNCTION public.insert_account(name character varying, surname character varying, email character varying, password character, birthdate date) OWNER TO postgres;

--
-- Name: insert_account_and_student(character varying, character varying, character varying, character, date, public.status, date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_account_and_student(name character varying, surname character varying, email character varying, password character, birthdate date, status public.status, enrollment_date date, degree character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    account_id INTEGER;
BEGIN
    -- Insert into the account table and return the inserted ID
    INSERT INTO account(id, name, surname, email, password, birthdate) VALUES (default, name, surname, email, password, birthdate) RETURNING id INTO account_id;

    -- Insert into the student table, referencing the inserted account_id
    INSERT INTO student VALUES (account_id, status, enrollment_date, degree);

    -- Return the inserted account_id
    RETURN account_id;
END;
$$;


ALTER FUNCTION public.insert_account_and_student(name character varying, surname character varying, email character varying, password character, birthdate date, status public.status, enrollment_date date, degree character varying) OWNER TO postgres;

--
-- Name: max_owner(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.max_owner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    owner_count INTEGER;
BEGIN
    SELECT count(*) INTO owner_count
    FROM course c
    WHERE c.owner = NEW.owner;

    IF owner_count >= 3 THEN
        RAISE EXCEPTION 'Too many courses belonging to this teacher';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.max_owner() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    surname character varying(50) NOT NULL,
    email character varying(320) NOT NULL,
    password character varying(82) NOT NULL,
    birthdate date
);


ALTER TABLE public.account OWNER TO postgres;

--
-- Name: account_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_id_seq OWNER TO postgres;

--
-- Name: account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_id_seq OWNED BY public.account.id;


--
-- Name: course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course (
    id integer NOT NULL,
    degree integer NOT NULL,
    owner integer NOT NULL,
    name character varying(60) NOT NULL,
    description text,
    year smallint
);


ALTER TABLE public.course OWNER TO postgres;

--
-- Name: course_degree_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_degree_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_degree_seq OWNER TO postgres;

--
-- Name: course_degree_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_degree_seq OWNED BY public.course.degree;


--
-- Name: course_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_id_seq OWNER TO postgres;

--
-- Name: course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_id_seq OWNED BY public.course.id;


--
-- Name: course_owner_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_owner_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.course_owner_seq OWNER TO postgres;

--
-- Name: course_owner_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_owner_seq OWNED BY public.course.owner;


--
-- Name: degree; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.degree (
    id integer NOT NULL,
    name character varying(60) NOT NULL
);


ALTER TABLE public.degree OWNER TO postgres;

--
-- Name: degree_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.degree_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.degree_id_seq OWNER TO postgres;

--
-- Name: degree_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.degree_id_seq OWNED BY public.degree.id;


--
-- Name: enrollment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enrollment (
    exam integer NOT NULL,
    student integer NOT NULL,
    mark integer
);


ALTER TABLE public.enrollment OWNER TO postgres;

--
-- Name: enrollment_exam_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enrollment_exam_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.enrollment_exam_seq OWNER TO postgres;

--
-- Name: enrollment_exam_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.enrollment_exam_seq OWNED BY public.enrollment.exam;


--
-- Name: enrollment_student_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enrollment_student_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.enrollment_student_seq OWNER TO postgres;

--
-- Name: enrollment_student_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.enrollment_student_seq OWNED BY public.enrollment.student;


--
-- Name: exam; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    room character varying(60) NOT NULL,
    date timestamp without time zone NOT NULL,
    course integer
);


ALTER TABLE public.exam OWNER TO postgres;

--
-- Name: exam_degree_id; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_degree_id (
    degree integer
);


ALTER TABLE public.exam_degree_id OWNER TO postgres;

--
-- Name: exam_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exam_id_seq OWNER TO postgres;

--
-- Name: exam_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_id_seq OWNED BY public.exam.id;


--
-- Name: propedeucity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.propedeucity (
    course integer NOT NULL,
    propedeutic_course integer NOT NULL
);


ALTER TABLE public.propedeucity OWNER TO postgres;

--
-- Name: propedeucity_course_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.propedeucity_course_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.propedeucity_course_seq OWNER TO postgres;

--
-- Name: propedeucity_course_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.propedeucity_course_seq OWNED BY public.propedeucity.course;


--
-- Name: propedeucity_propedeutic_course_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.propedeucity_propedeutic_course_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.propedeucity_propedeutic_course_seq OWNER TO postgres;

--
-- Name: propedeucity_propedeutic_course_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.propedeucity_propedeutic_course_seq OWNED BY public.propedeucity.propedeutic_course;


--
-- Name: secretary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.secretary (
    id integer NOT NULL
);


ALTER TABLE public.secretary OWNER TO postgres;

--
-- Name: secretary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.secretary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.secretary_id_seq OWNER TO postgres;

--
-- Name: secretary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.secretary_id_seq OWNED BY public.secretary.id;


--
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    id integer NOT NULL,
    current_status public.status,
    enrollment_date date,
    degree_course character varying(60) NOT NULL,
    degree integer
);


ALTER TABLE public.student OWNER TO postgres;

--
-- Name: student_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_id_seq OWNER TO postgres;

--
-- Name: student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_id_seq OWNED BY public.student.id;


--
-- Name: teacher; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher (
    id integer NOT NULL
);


ALTER TABLE public.teacher OWNER TO postgres;

--
-- Name: teacher_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_id_seq OWNER TO postgres;

--
-- Name: teacher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_id_seq OWNED BY public.teacher.id;


--
-- Name: account id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account ALTER COLUMN id SET DEFAULT nextval('public.account_id_seq'::regclass);


--
-- Name: course id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course ALTER COLUMN id SET DEFAULT nextval('public.course_id_seq'::regclass);


--
-- Name: course degree; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course ALTER COLUMN degree SET DEFAULT nextval('public.course_degree_seq'::regclass);


--
-- Name: course owner; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course ALTER COLUMN owner SET DEFAULT nextval('public.course_owner_seq'::regclass);


--
-- Name: degree id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree ALTER COLUMN id SET DEFAULT nextval('public.degree_id_seq'::regclass);


--
-- Name: enrollment exam; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment ALTER COLUMN exam SET DEFAULT nextval('public.enrollment_exam_seq'::regclass);


--
-- Name: enrollment student; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment ALTER COLUMN student SET DEFAULT nextval('public.enrollment_student_seq'::regclass);


--
-- Name: exam id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam ALTER COLUMN id SET DEFAULT nextval('public.exam_id_seq'::regclass);


--
-- Name: propedeucity course; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propedeucity ALTER COLUMN course SET DEFAULT nextval('public.propedeucity_course_seq'::regclass);


--
-- Name: propedeucity propedeutic_course; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propedeucity ALTER COLUMN propedeutic_course SET DEFAULT nextval('public.propedeucity_propedeutic_course_seq'::regclass);


--
-- Name: secretary id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secretary ALTER COLUMN id SET DEFAULT nextval('public.secretary_id_seq'::regclass);


--
-- Name: student id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student ALTER COLUMN id SET DEFAULT nextval('public.student_id_seq'::regclass);


--
-- Name: teacher id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher ALTER COLUMN id SET DEFAULT nextval('public.teacher_id_seq'::regclass);


--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account (id, name, surname, email, password, birthdate) FROM stdin;
4	Mimmo	Lastrato	m.lastrato@studenti.it	$2a$06$369MWm29JDi.R5ZGHE/KaeaGY.Cr2.Hi9pe2.1aZ8ZZEObnGcfGbG	1998-02-11
5	Lauro	Minniti	l.minniti@studenti.it	$2a$06$JXY1T3OFObXlbbrws42gvujDdTR34Xq3Mfd9hXDJmvYKRrM8QF9CK	1999-01-12
7	Carlo	Conti	c.conti@professori.it	$2a$06$G7m/h0lT4Q2JD19ULox/re2RBoyNrSaF02VRDTkdVZAfc6/o0PzX.	1960-03-12
8	Mike	Buongiorno	m.buongiorno@studenti.it	$2a$06$LWFuPFE1IExIgZBr98JgbOKOlTIfZMo98SQpcxhPi3NJBJKacoQz.	1922-01-12
23	Gennaro	Stelvio	g.stelvio@studenti.it	$2a$06$tBqHE3YWFtE1ACpomGAzReA93FrdSuInNfbRTNcbZOnOitIs9YlZy	1999-01-12
6	Pippo	Baudo	p.baudo@professori.it	asdfasdfasdf	1850-01-12
3	Mario	Rossi	m.rossi@studenti.it	$2y$10$CzYkOPgghSAh0eHZR5j/F.gxPj55cY3.5wO9zrSBIWyqSUs3G6VO6	2000-06-12
9	Rocco	Strapozzo	r.strapozzo@segreteria.it	$2y$10$Y/judKA38rt6uV1gdxu7.uCdUQyBidcdEv2ivaaKLz075BgPzQ5qm	1970-01-12
\.


--
-- Data for Name: course; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course (id, degree, owner, name, description, year) FROM stdin;
2	1	6	Databases	A course about databases	2
3	1	6	Programming I	An introductory course about programming	1
4	1	8	Discrete Math	A course about discrete math	1
5	2	6	Physics I	A course about discrete math	1
6	3	8	Human relations	A course about human relations	1
\.


--
-- Data for Name: degree; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.degree (id, name) FROM stdin;
1	Computer Science
2	Physics
3	Philosophy
\.


--
-- Data for Name: enrollment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enrollment (exam, student, mark) FROM stdin;
4	3	\N
2	3	19
3	3	19
\.


--
-- Data for Name: exam; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam (id, name, room, date, course) FROM stdin;
2	Exam of Discrete Math	Aula B2	2024-01-12 00:00:00	4
3	Exam of Databases	Aula B1	2024-03-11 00:00:00	2
4	Exam of Programing I	Aula C1	2024-04-11 00:00:00	3
19	Exam of Physics I	Aula Magna	2024-03-12 00:00:00	5
\.


--
-- Data for Name: exam_degree_id; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_degree_id (degree) FROM stdin;
2
\.


--
-- Data for Name: propedeucity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.propedeucity (course, propedeutic_course) FROM stdin;
2	3
\.


--
-- Data for Name: secretary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.secretary (id) FROM stdin;
9
\.


--
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student (id, current_status, enrollment_date, degree_course, degree) FROM stdin;
4	enrolled	2021-02-11	Mathematics	2
5	enrolled	2020-11-08	Computer Science	1
23	resigned	2021-02-11	Mathematics	\N
3	enrolled	2021-01-01	Computer Science	1
\.


--
-- Data for Name: teacher; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher (id) FROM stdin;
6
8
\.


--
-- Name: account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.account_id_seq', 25, true);


--
-- Name: course_degree_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_degree_seq', 1, false);


--
-- Name: course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_id_seq', 29, true);


--
-- Name: course_owner_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_owner_seq', 1, false);


--
-- Name: degree_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.degree_id_seq', 7, true);


--
-- Name: enrollment_exam_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enrollment_exam_seq', 1, false);


--
-- Name: enrollment_student_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enrollment_student_seq', 1, false);


--
-- Name: exam_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_id_seq', 22, true);


--
-- Name: propedeucity_course_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.propedeucity_course_seq', 1, false);


--
-- Name: propedeucity_propedeutic_course_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.propedeucity_propedeutic_course_seq', 1, false);


--
-- Name: secretary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.secretary_id_seq', 1, false);


--
-- Name: student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_id_seq', 1, false);


--
-- Name: teacher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_id_seq', 1, false);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);


--
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (id);


--
-- Name: degree degree_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree
    ADD CONSTRAINT degree_pkey PRIMARY KEY (id);


--
-- Name: enrollment enrollment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT enrollment_pkey PRIMARY KEY (exam, student);


--
-- Name: exam exam_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam
    ADD CONSTRAINT exam_pkey PRIMARY KEY (id);


--
-- Name: propedeucity propedeucity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propedeucity
    ADD CONSTRAINT propedeucity_pkey PRIMARY KEY (course, propedeutic_course);


--
-- Name: secretary secretary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secretary
    ADD CONSTRAINT secretary_pkey PRIMARY KEY (id);


--
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (id);


--
-- Name: teacher teacher_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_pkey PRIMARY KEY (id);


--
-- Name: enrollment enrollment_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER enrollment_check BEFORE INSERT ON public.enrollment FOR EACH ROW EXECUTE FUNCTION public.check_enrollment();


--
-- Name: course max_owner; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER max_owner BEFORE INSERT ON public.course FOR EACH ROW EXECUTE FUNCTION public.max_owner();


--
-- Name: exam overlap_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER overlap_check BEFORE INSERT ON public.exam FOR EACH ROW EXECUTE FUNCTION public.check_overlap();


--
-- Name: course course_degree_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_degree_fkey FOREIGN KEY (degree) REFERENCES public.degree(id);


--
-- Name: course course_owner_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_owner_fkey FOREIGN KEY (owner) REFERENCES public.teacher(id);


--
-- Name: enrollment enrollment_exam_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT enrollment_exam_fkey FOREIGN KEY (exam) REFERENCES public.exam(id) ON DELETE CASCADE;


--
-- Name: enrollment enrollment_student_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT enrollment_student_fkey FOREIGN KEY (student) REFERENCES public.student(id);


--
-- Name: exam exam_course_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam
    ADD CONSTRAINT exam_course_fkey FOREIGN KEY (course) REFERENCES public.course(id);


--
-- Name: propedeucity propedeucity_course_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propedeucity
    ADD CONSTRAINT propedeucity_course_fkey FOREIGN KEY (course) REFERENCES public.course(id);


--
-- Name: propedeucity propedeucity_propedeutic_course_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propedeucity
    ADD CONSTRAINT propedeucity_propedeutic_course_fkey FOREIGN KEY (propedeutic_course) REFERENCES public.course(id);


--
-- Name: secretary secretary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secretary
    ADD CONSTRAINT secretary_id_fkey FOREIGN KEY (id) REFERENCES public.account(id);


--
-- Name: student student_degree_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_degree_fkey FOREIGN KEY (degree) REFERENCES public.degree(id);


--
-- Name: student student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_id_fkey FOREIGN KEY (id) REFERENCES public.account(id);


--
-- Name: teacher teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_id_fkey FOREIGN KEY (id) REFERENCES public.account(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

