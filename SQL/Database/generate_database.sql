
CREATE TABLE admin (
    admin_id SERIAL PRIMARY KEY,
    admin_full_name VARCHAR(50) NOT NULL,
    admin_email VARCHAR(50) NOT NULL,
    admin_phone_number CHAR(11) NOT NULL
);

CREATE TABLE client (
    client_id SERIAL PRIMARY KEY,
    admin_id INT NOT NULL REFERENCES admin(admin_id) ON DELETE RESTRICT,
    client_full_name VARCHAR(50) NOT NULL,
    client_registration_date DATE NOT NULL,
    client_birthday DATE NOT NULL,
    client_contacts VARCHAR(100) NOT NULL
);

CREATE TABLE instructor (
    instructor_number DECIMAL(10) PRIMARY KEY,
    instructor_full_name VARCHAR(50) NOT NULL,
    instructor_specialization VARCHAR(50) NOT NULL
);

CREATE TABLE schedule (
    schedule_id SERIAL PRIMARY KEY,
    admin_id INT NOT NULL REFERENCES admin(admin_id) ON DELETE RESTRICT,
    instructor_number DECIMAL(10) NOT NULL REFERENCES instructor(instructor_number) ON DELETE RESTRICT,
    schedule_name VARCHAR(50) NOT NULL,
    schedule_type VARCHAR(15) NOT NULL,
    schedule_time TIMESTAMP NOT NULL,
    schedule_number_of_seats INT NOT NULL
);

CREATE TABLE subscription (
    subscription_id SERIAL PRIMARY KEY,
    admin_id INT NOT NULL REFERENCES admin(admin_id) ON DELETE RESTRICT,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE RESTRICT,
    subscription_type VARCHAR(10) NOT NULL,
    subscription_price DECIMAL(8,2) NOT NULL,
    subscription_period INT NOT NULL,
    subscription_status BOOLEAN NOT NULL
);

CREATE TABLE payments (
    payments_number SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE RESTRICT,
    payments_date TIMESTAMP NOT NULL,
    payments_purpose VARCHAR(100) NOT NULL,
    payments_amounts DECIMAL(8,2) NOT NULL,
    payments_method VARCHAR(10) NOT NULL
);

CREATE TABLE registration (
    registration_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE CASCADE,
    instructor_number DECIMAL(10) NOT NULL REFERENCES instructor(instructor_number) ON DELETE CASCADE,
    registration_date DATE NOT NULL,
    registration_time TIME NOT NULL,
    registration_timestamp TIMESTAMP GENERATED ALWAYS AS (registration_date + registration_time) STORED,
    registration_status BOOLEAN NOT NULL
);

CREATE TABLE participates (
    schedule_id INT NOT NULL REFERENCES schedule(schedule_id) ON DELETE CASCADE,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE CASCADE,
    PRIMARY KEY (schedule_id, client_id)
);



CREATE INDEX IDX_CLIENT_NAME ON client (client_full_name);
CREATE INDEX IDX_INSTRUCTOR_NAME ON instructor (instructor_full_name);
CREATE INDEX IDX_ACTIVE_SUBS ON subscription (subscription_status);
CREATE INDEX pays_FK ON payments (client_id);
CREATE INDEX purchases_FK ON subscription (client_id);
CREATE INDEX undergoing_FK ON registration (client_id);
CREATE INDEX conducts_FK ON registration (instructor_number);
