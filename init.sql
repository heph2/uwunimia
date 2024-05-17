

-- Enable extensions
CREATE EXTENSION pgcrypto;

CREATE TABLE IF NOT EXISTS account (
       id serial PRIMARY KEY,
       name varchar(50) NOT NULL,
       surname varchar(50) NOT NULL,
       email varchar(320) NOT NULL UNIQUE, --  64 characters for local part + @ + 255 for domain
       password char(82) NOT NULL, -- Hash using bcrypt
       birthdate date
);


CREATE TYPE status AS ENUM ('enrolled', 'resigned', 'graduate');
CREATE TABLE IF NOT EXISTS student (
       id serial,
       current_status status NOT NULL,
       enrollment_date date NOT NULL,
       degree integer NOT NULL,
       PRIMARY KEY (id),
       FOREIGN KEY (id) REFERENCES account(id),
       FOREIGN KEY (degree) REFERENCES degree(id)
);

CREATE TABLE IF NOT EXISTS teacher (
       id serial,
       PRIMARY KEY (id),
       FOREIGN KEY (id) REFERENCES account(id)
);

CREATE TABLE IF NOT EXISTS secretary (
       id serial,
       PRIMARY KEY (id),
       FOREIGN KEY (id) REFERENCES account(id)
);

CREATE TABLE IF NOT EXISTS degree (
       id serial PRIMARY KEY,
       name varchar(60) NOT NULL
);


CREATE OR REPLACE FUNCTION check_overlap()
RETURNS TRIGGER AS
$$
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
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION max_owner()
RETURNS TRIGGER AS
$$
BEGIN
    DECLARE
	owner_count INTEGER;
    BEGIN

    SELECT count(owner) INTO owner_count
    FROM course c WHERE owner = NEW.owner
    
    IF (owner_count >= 3) (
    ) THEN
      RAISE EXCEPTION 'Too many courses belonging to this teacher';
    END IF;

    RETURN NEW;

    END;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER overlap_check
       BEFORE INSERT ON exam
       FOR EACH ROW
       EXECUTE FUNCTION check_overlap();

CREATE TABLE IF NOT EXISTS exam (
       id serial PRIMARY KEY,
       name varchar(60) NOT NULL,
       room varchar(60) NOT NULL,
       course integer NOT NULL,
       FOREIGN KEY (course) REFERENCES course(id)
       date timestamp NOT NULL
);

-- Check enrollment on degree and propedeucity
CREATE OR REPLACE FUNCTION check_enrollment()
RETURNS TRIGGER AS
$$
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
$$
LANGUAGE plpgsql;


CREATE TRIGGER enrollment_check
       BEFORE INSERT ON enrollment
       FOR EACH ROW
       EXECUTE FUNCTION check_enrollment();

CREATE TABLE IF NOT EXISTS enrollment (
       exam serial,
       student serial,
       mark INT,
       PRIMARY KEY (exam, student),
       FOREIGN KEY (exam) REFERENCES exam(id) ON DELETE cascade ON UPDATE no action,
       FOREIGN KEY (student) REFERENCES student(id),
       CHECK (mark>=0 AND mark <=30)
);

CREATE TRIGGER max_owner
       BEFORE INSERT ON course
       FOR EACH ROW
       EXECUTE FUNCTION max_owner();

CREATE TABLE IF NOT EXISTS course (
       id serial PRIMARY KEY,
       degree serial NOT NULL,
       owner serial NOT NULL,
       name varchar(60) NOT NULL,
       description text,
       year smallint,
       FOREIGN KEY (degree) REFERENCES degree(id),
       FOREIGN KEY (owner) REFERENCES teacher(id)
);

CREATE TABLE IF NOT EXISTS propedeucity (
       course serial,
       propedeutic_course serial,
       PRIMARY KEY (course, propedeutic_course),
       FOREIGN KEY (course) REFERENCES course(id),
       FOREIGN KEY (propedeutic_course) REFERENCES course(id)
);

CREATE VIEW carrier AS
       SELECT (name, room, date, mark)
       FROM enrollment enr
       JOIN exam e ON e.id = enr.exam;

CREATE VIEW carrier_valid AS
       SELECT (name, room, date, mark)
       FROM enrollment enr
       JOIN exam e ON e.id = enr.exam WHERE mark >= 18;

CREATE VIEW course_info AS
       SELECT DISTINCT a.name, a.surname, c.name, c.description, c.year, d.name
       FROM teacher t
       JOIN account a ON t.id = a.id
       JOIN course c ON t.id = c.owner
       JOIN degree d ON c.degree = d.id;
       
-- Populate --

INSERT INTO account VALUES (
       DEFAULT,
       'Mario',
       'Rossi',
       'm.rossi@studenti.it',
       crypt('mariopassword', gen_salt('bf')),
       '2000-06-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Mimmo',
       'Lastrato',
       'm.lastrato@studenti.it',
       crypt('mimmopassword', gen_salt('bf')),
       '1998-02-11'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Lauro',
       'Minniti',
       'l.minniti@studenti.it',
       crypt('lauropassword', gen_salt('bf')),
       '1999-01-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Pippo',
       'Baudo',
       'p.baudo@professori.it',
       crypt('pippopassword', gen_salt('bf')),
       '1850-01-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Carlo',
       'Conti',
       'c.conti@professori.it',
       crypt('carlopassword', gen_salt('bf')),
       '1960-03-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Mike',
       'Buongiorno',
       'm.buongiorno@studenti.it',
       crypt('mikepassword', gen_salt('bf')),
       '1922-01-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Rocco',
       'Strapozzo',
       'r.strapozzo@studenti.it',
       crypt('roccopassword', gen_salt('bf')),
       '1970-01-12'
);

INSERT INTO account VALUES (
       DEFAULT,
       'Gennaro',
       'Stelvio',
       'g.stelvio@studenti.it',
       crypt('gennaropassword', gen_salt('bf')),
       '1999-01-12'
);

INSERT INTO student VALUES (
       (SELECT id from account where name = 'Mario' and surname = 'Rossi'),
       'enrolled',
       '2021-01-01',
       'Computer Science'
);

INSERT INTO student VALUES (
       (SELECT id from account where name = 'Mimmo' and surname = 'Lastrato'),
       'enrolled',
       '2021-02-11',
       'Mathematics'
);

INSERT INTO student VALUES (
       (SELECT id from account where name = 'Gennaro' and surname = 'Stelvio'),
       'resigned',
       '2021-02-11',
       'Mathematics'
);

INSERT INTO student VALUES (
       (SELECT id from account where name = 'Lauro' and surname = 'Minniti'),
       'enrolled',
       '2020-11-08',
       'Computer Science'
);

INSERT INTO teacher VALUES (
       (SELECT id from account where name = 'Pippo' and surname = 'Baudo')
);

INSERT INTO teacher VALUES (
       (SELECT id from account where name = 'Carlo' and surname = 'Conti')
);

INSERT INTO teacher VALUES (
       (SELECT id from account where name = 'Mike' and surname = 'Buongiorno')
);

INSERT INTO secretary VALUES (
       (SELECT id from account where name = 'Rocco')
);

INSERT INTO degree VALUES (
       DEFAULT,
       'Computer Science'
);

INSERT INTO degree VALUES (
       DEFAULT,
       'Mathematics'
);

INSERT INTO degree VALUES (
       DEFAULT,
       'Physics'
);

INSERT INTO degree VALUES (
       DEFAULT,
       'Philosophy'
);

INSERT INTO course VALUES (
       DEFAULT,
       (SELECT id from degree where name = 'Computer Science'),
       (SELECT id from teacher where id = 6),
       'Databases',
       'A course about databases',
       2
);

INSERT INTO course VALUES (
       DEFAULT,
       (SELECT id from degree where name = 'Computer Science'),
       (SELECT id from teacher where id = 6),
       'Programming I',
       'An introductory course about programming',
       1
);

INSERT INTO course VALUES (
       DEFAULT,
       (SELECT id from degree where name = 'Computer Science'),
       (SELECT id from teacher where id = 8),
       'Discrete Math',
       'A course about discrete math',
       1
);

INSERT INTO course VALUES (
       DEFAULT,
       (SELECT id from degree where name = 'Physics'),
       (SELECT id from teacher where id = 6),
       'Physics I',
       'A course about discrete math',
       1
);

INSERT INTO course VALUES (
       DEFAULT,
       (SELECT id from degree where name = 'Philosophy'),
       (SELECT id from teacher where id = 8),
       'Human relations',
       'A course about human relations',
       1
);

INSERT INTO propedeucity VALUES (
       (SELECT id from course where name = 'Databases'),
       (SELECT id from course where name = 'Programming I')
);

-- need to add course
INSERT INTO exam VALUES (
       DEFAULT,
       'Exam of Physics I',
       'Aula Magna',
       '2024-03-12'
);

INSERT INTO exam VALUES (
       DEFAULT,
       'Exam of Discrete Math',
       'Aula B2',
       '2024-01-12'
);

INSERT INTO exam VALUES (
       DEFAULT,
       'Exam of Databases',
       'Aula B1',
       '2024-03-11',
       (select id from course where name = 'Databases')
);

INSERT INTO exam VALUES (
       DEFAULT,
       'Exam of Programing I',
       'Aula C1',
       '2024-04-11',
       (select id from course where name = 'Programming I')
);

INSERT INTO enrollment VALUES (
       (SELECT id from exam where name = 'Exam of Physics I'),
       (SELECT id from student where id = 3)
);

