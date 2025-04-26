--======================================================================================================================
-- DB creation
--======================================================================================================================

-- Create Database and Schema (if they don't exist)
DROP DATABASE IF EXISTS fuel_network_db;
CREATE DATABASE fuel_network_db;

-- Connect to the database
\c fuel_network_db

-- Create schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS fuel_net;

-- Set search path
SET search_path TO fuel_net, public;

-- STATION Table
CREATE TABLE IF NOT EXISTS fuel_net.station
(
    station_id     SERIAL PRIMARY KEY,
    station_name   VARCHAR(100)  NOT NULL,
    address        VARCHAR(200)  NOT NULL,
    city           VARCHAR(100)  NOT NULL,
    state_province VARCHAR(50)   NOT NULL,
    postal_code    VARCHAR(20)   NOT NULL,
    country        VARCHAR(50)   NOT NULL,
    phone          VARCHAR(15)   NOT NULL,
    latitude       DECIMAL(9, 6) NOT NULL,
    longitude      DECIMAL(9, 6) NOT NULL,
    opening_time   TIME          NOT NULL,
    closing_time   TIME          NOT NULL,
    is_24hr        BOOLEAN   DEFAULT FALSE,
    owner_id       INTEGER       NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    full_address   VARCHAR(400) GENERATED ALWAYS AS (address || ', ' || city || ', ' || state_province || ' ' ||
                                                     postal_code || ', ' || country) STORED
);

-- FUEL_TYPE Table
CREATE TABLE IF NOT EXISTS fuel_net.fuel_type
(
    fuel_type_id SERIAL PRIMARY KEY,
    fuel_name    VARCHAR(50) NOT NULL,
    description  VARCHAR(255),
    is_active    BOOLEAN   DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add unique constraint if it doesn't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_fuel_name'
                         AND conrelid = 'fuel_net.fuel_type'::regclass) THEN
            ALTER TABLE fuel_net.fuel_type
                ADD CONSTRAINT uk_fuel_name UNIQUE (fuel_name);
        END IF;
    END
$$;

-- SUPPLIER Table
CREATE TABLE IF NOT EXISTS fuel_net.supplier
(
    supplier_id    SERIAL PRIMARY KEY,
    supplier_name  VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(15)  NOT NULL,
    address        VARCHAR(200) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    state_province VARCHAR(50)  NOT NULL,
    postal_code    VARCHAR(20)  NOT NULL,
    country        VARCHAR(50)  NOT NULL,
    is_active      BOOLEAN   DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add unique constraint if it doesn't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_supplier_name'
                         AND conrelid = 'fuel_net.supplier'::regclass) THEN
            ALTER TABLE fuel_net.supplier
                ADD CONSTRAINT uk_supplier_name UNIQUE (supplier_name);
        END IF;
    END
$$;

-- CUSTOMER Table
CREATE TABLE IF NOT EXISTS fuel_net.customer
(
    customer_id       SERIAL PRIMARY KEY,
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    email             VARCHAR(100) NOT NULL,
    phone             VARCHAR(15)  NOT NULL,
    address           VARCHAR(200),
    city              VARCHAR(100),
    state_province    VARCHAR(50),
    postal_code       VARCHAR(20),
    country           VARCHAR(50),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    has_loyalty_card  BOOLEAN   DEFAULT FALSE,
    is_active         BOOLEAN   DEFAULT TRUE,
    full_name         VARCHAR(201) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

-- Add unique constraint if it doesn't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_customer_email'
                         AND conrelid = 'fuel_net.customer'::regclass) THEN
            ALTER TABLE fuel_net.customer
                ADD CONSTRAINT uk_customer_email UNIQUE (email);
        END IF;
    END
$$;

-- EMPLOYEE Table
CREATE TABLE IF NOT EXISTS fuel_net.employee
(
    employee_id      SERIAL PRIMARY KEY,
    first_name       VARCHAR(100)   NOT NULL,
    last_name        VARCHAR(100)   NOT NULL,
    email            VARCHAR(100)   NOT NULL,
    phone            VARCHAR(15)    NOT NULL,
    address          VARCHAR(200)   NOT NULL,
    city             VARCHAR(100)   NOT NULL,
    state_province   VARCHAR(50)    NOT NULL,
    postal_code      VARCHAR(20)    NOT NULL,
    country          VARCHAR(50)    NOT NULL,
    hire_date        DATE           NOT NULL,
    termination_date DATE,
    station_id       INTEGER        NOT NULL,
    position         VARCHAR(50)    NOT NULL,
    hourly_rate      DECIMAL(10, 2) NOT NULL,
    is_active        BOOLEAN DEFAULT TRUE
);

-- Add unique constraint and foreign key if they don't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_employee_email'
                         AND conrelid = 'fuel_net.employee'::regclass) THEN
            ALTER TABLE fuel_net.employee
                ADD CONSTRAINT uk_employee_email UNIQUE (email);
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_employee_station'
                         AND conrelid = 'fuel_net.employee'::regclass) THEN
            ALTER TABLE fuel_net.employee
                ADD CONSTRAINT fk_employee_station FOREIGN KEY (station_id)
                    REFERENCES fuel_net.station (station_id) ON DELETE RESTRICT;
        END IF;
    END
$$;

-- STATION_FUEL Table (Junction Table)
CREATE TABLE IF NOT EXISTS fuel_net.station_fuel
(
    station_fuel_id      SERIAL PRIMARY KEY,
    station_id           INTEGER        NOT NULL,
    fuel_type_id         INTEGER        NOT NULL,
    regular_price        DECIMAL(10, 2) NOT NULL,
    discounted_price     DECIMAL(10, 2),
    current_quantity     INTEGER        NOT NULL DEFAULT 0,
    capacity             INTEGER        NOT NULL,
    is_available         BOOLEAN                 DEFAULT TRUE,
    last_updated         TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    available_percentage DECIMAL(5, 2) GENERATED ALWAYS AS (
        CASE
            WHEN capacity = 0 THEN 0
            ELSE (current_quantity * 100.0 / capacity)
            END
        ) STORED
);

-- Add constraints if they don't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_station_fuel_station'
                         AND conrelid = 'fuel_net.station_fuel'::regclass) THEN
            ALTER TABLE fuel_net.station_fuel
                ADD CONSTRAINT fk_station_fuel_station FOREIGN KEY (station_id)
                    REFERENCES fuel_net.station (station_id) ON DELETE CASCADE;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_station_fuel_type'
                         AND conrelid = 'fuel_net.station_fuel'::regclass) THEN
            ALTER TABLE fuel_net.station_fuel
                ADD CONSTRAINT fk_station_fuel_type FOREIGN KEY (fuel_type_id)
                    REFERENCES fuel_net.fuel_type (fuel_type_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_station_fuel'
                         AND conrelid = 'fuel_net.station_fuel'::regclass) THEN
            ALTER TABLE fuel_net.station_fuel
                ADD CONSTRAINT uk_station_fuel UNIQUE (station_id, fuel_type_id);
        END IF;
    END
$$;

-- FUEL_DELIVERY Table
CREATE TABLE IF NOT EXISTS fuel_net.fuel_delivery
(
    delivery_id    SERIAL PRIMARY KEY,
    station_id     INTEGER        NOT NULL,
    supplier_id    INTEGER        NOT NULL,
    fuel_type_id   INTEGER        NOT NULL,
    delivery_date  TIMESTAMP      NOT NULL,
    quantity       DECIMAL(10, 2) NOT NULL,
    unit_price     DECIMAL(10, 2) NOT NULL,
    total_cost     DECIMAL(10, 2) NOT NULL,
    invoice_number VARCHAR(100)   NOT NULL,
    is_received    BOOLEAN DEFAULT FALSE,
    received_by    VARCHAR(100),
    received_at    TIMESTAMP,
    notes          VARCHAR(255)
);

-- Add constraints if they don't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_delivery_station'
                         AND conrelid = 'fuel_net.fuel_delivery'::regclass) THEN
            ALTER TABLE fuel_net.fuel_delivery
                ADD CONSTRAINT fk_delivery_station FOREIGN KEY (station_id)
                    REFERENCES fuel_net.station (station_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_delivery_supplier'
                         AND conrelid = 'fuel_net.fuel_delivery'::regclass) THEN
            ALTER TABLE fuel_net.fuel_delivery
                ADD CONSTRAINT fk_delivery_supplier FOREIGN KEY (supplier_id)
                    REFERENCES fuel_net.supplier (supplier_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_delivery_fuel_type'
                         AND conrelid = 'fuel_net.fuel_delivery'::regclass) THEN
            ALTER TABLE fuel_net.fuel_delivery
                ADD CONSTRAINT fk_delivery_fuel_type FOREIGN KEY (fuel_type_id)
                    REFERENCES fuel_net.fuel_type (fuel_type_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'uk_invoice_number'
                         AND conrelid = 'fuel_net.fuel_delivery'::regclass) THEN
            ALTER TABLE fuel_net.fuel_delivery
                ADD CONSTRAINT uk_invoice_number UNIQUE (invoice_number);
        END IF;
    END
$$;

-- FUEL_SALE Table
CREATE TABLE IF NOT EXISTS fuel_net.fuel_sale
(
    sale_id                  SERIAL PRIMARY KEY,
    station_id               INTEGER        NOT NULL,
    fuel_type_id             INTEGER        NOT NULL,
    customer_id              INTEGER,
    employee_id              INTEGER        NOT NULL,
    sale_datetime            TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity_sold            DECIMAL(10, 2) NOT NULL,
    unit_price               DECIMAL(10, 2) NOT NULL,
    total_amount             DECIMAL(10, 2) NOT NULL,
    payment_method           VARCHAR(50)    NOT NULL,
    payment_reference        VARCHAR(100),
    loyalty_discount_applied BOOLEAN                 DEFAULT FALSE
);

-- Add constraints if they don't exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_sale_station'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT fk_sale_station FOREIGN KEY (station_id)
                    REFERENCES fuel_net.station (station_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_sale_fuel_type'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT fk_sale_fuel_type FOREIGN KEY (fuel_type_id)
                    REFERENCES fuel_net.fuel_type (fuel_type_id) ON DELETE RESTRICT;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_sale_customer'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id)
                    REFERENCES fuel_net.customer (customer_id) ON DELETE SET NULL;
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'fk_sale_employee'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT fk_sale_employee FOREIGN KEY (employee_id)
                    REFERENCES fuel_net.employee (employee_id) ON DELETE RESTRICT;
        END IF;
    END
$$;

-- Add CHECK constraints if they don't exist

-- 1. Ensure delivery date is after January 1, 2024
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_valid_delivery_date'
                         AND conrelid = 'fuel_net.fuel_delivery'::regclass) THEN
            ALTER TABLE fuel_net.fuel_delivery
                ADD CONSTRAINT chk_valid_delivery_date
                    CHECK (delivery_date > '2024-01-01 00:00:00');
        END IF;
    END
$$;

-- 2. Ensure fuel quantity sold is positive
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_positive_quantity_sold'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT chk_positive_quantity_sold
                    CHECK (quantity_sold > 0);
        END IF;
    END
$$;

-- 3. Ensure fuel capacity is greater than zero
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_positive_capacity'
                         AND conrelid = 'fuel_net.station_fuel'::regclass) THEN
            ALTER TABLE fuel_net.station_fuel
                ADD CONSTRAINT chk_positive_capacity
                    CHECK (capacity > 0);
        END IF;
    END
$$;

-- 4. Ensure hourly rate is at least minimum wage ($15.00)
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_minimum_hourly_rate'
                         AND conrelid = 'fuel_net.employee'::regclass) THEN
            ALTER TABLE fuel_net.employee
                ADD CONSTRAINT chk_minimum_hourly_rate
                    CHECK (hourly_rate >= 15.00);
        END IF;
    END
$$;

-- 5. Ensure payment method is one of the allowed values
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_valid_payment_method'
                         AND conrelid = 'fuel_net.fuel_sale'::regclass) THEN
            ALTER TABLE fuel_net.fuel_sale
                ADD CONSTRAINT chk_valid_payment_method
                    CHECK (payment_method IN ('CASH', 'CARD', 'LOYALTY_POINTS'));
        END IF;
    END
$$;

-- 6. Ensure closing time is after opening time (unless 24hr)
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_valid_business_hours'
                         AND conrelid = 'fuel_net.station'::regclass) THEN
            ALTER TABLE fuel_net.station
                ADD CONSTRAINT chk_valid_business_hours
                    CHECK (is_24hr = TRUE OR closing_time > opening_time);
        END IF;
    END
$$;

-- 7. Ensure termination date is after hire date
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_constraint
                       WHERE conname = 'chk_valid_employment_period'
                         AND conrelid = 'fuel_net.employee'::regclass) THEN
            ALTER TABLE fuel_net.employee
                ADD CONSTRAINT chk_valid_employment_period
                    CHECK (termination_date IS NULL OR termination_date > hire_date);
        END IF;
    END
$$;

--======================================================================================================================
-- DB population with data
--======================================================================================================================

-- Set search path
SET search_path TO fuel_net, public;

-- Create a temporary sequence for generating unique values
CREATE TEMPORARY SEQUENCE IF NOT EXISTS temp_seq;

-- Clear previous data
/*
TRUNCATE fuel_net.fuel_sale CASCADE;
TRUNCATE fuel_net.fuel_delivery CASCADE;
TRUNCATE fuel_net.station_fuel CASCADE;
TRUNCATE fuel_net.employee CASCADE;
TRUNCATE fuel_net.customer CASCADE;
TRUNCATE fuel_net.station CASCADE;
TRUNCATE fuel_net.supplier CASCADE;
TRUNCATE fuel_net.fuel_type CASCADE;
*/

-- Sample data for STATION table
INSERT INTO fuel_net.station (station_name, address, city, state_province,
                              postal_code, country, phone, latitude, longitude,
                              opening_time, closing_time, is_24hr, owner_id)
SELECT 'Station ' || nextval('temp_seq')::text                 AS station_name,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '123 Main Street'
           WHEN 1 THEN '456 Oak Avenue'
           WHEN 2 THEN '789 Pine Boulevard'
           WHEN 3 THEN '321 Elm Street'
           WHEN 4 THEN '654 Maple Road'
           WHEN 5 THEN '987 Cedar Lane'
           END                                                 AS address,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'New York'
           WHEN 1 THEN 'Los Angeles'
           WHEN 2 THEN 'Chicago'
           WHEN 3 THEN 'Houston'
           WHEN 4 THEN 'Phoenix'
           WHEN 5 THEN 'Philadelphia'
           END                                                 AS city,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'NY'
           WHEN 1 THEN 'CA'
           WHEN 2 THEN 'IL'
           WHEN 3 THEN 'TX'
           WHEN 4 THEN 'AZ'
           WHEN 5 THEN 'PA'
           END                                                 AS state_province,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '10001'
           WHEN 1 THEN '90001'
           WHEN 2 THEN '60601'
           WHEN 3 THEN '77001'
           WHEN 4 THEN '85001'
           WHEN 5 THEN '19101'
           END                                                 AS postal_code,
       'USA'                                                   AS country,
       '555-' || LPAD((100 + nextval('temp_seq') % 900)::text, 3, '0') || '-' ||
       LPAD((1000 + nextval('temp_seq') % 9000)::text, 4, '0') AS phone,
       40 + (nextval('temp_seq') % 10)::decimal / 10           AS latitude,
       -74 - (nextval('temp_seq') % 50)::decimal / 10          AS longitude,
       CASE (i % 3)
           WHEN 0 THEN '06:00:00'::time
           WHEN 1 THEN '05:00:00'::time
           WHEN 2 THEN '04:00:00'::time
           END                                                 AS opening_time,
       CASE (i % 3)
           WHEN 0 THEN '22:00:00'::time
           WHEN 1 THEN '23:00:00'::time
           WHEN 2 THEN '00:00:00'::time
           END                                                 AS closing_time,
       i % 3 = 2                                               AS is_24hr,
       (1000 + i)                                              AS owner_id
FROM generate_series(1, 8) i
ON CONFLICT DO NOTHING;

-- Reset sequence
ALTER SEQUENCE temp_seq RESTART;

-- Sample data for FUEL_TYPE table
INSERT INTO fuel_net.fuel_type (fuel_name, description, is_active)
VALUES ('Regular Gasoline', 'Standard unleaded gasoline (87 octane)', TRUE),
       ('Premium Gasoline', 'High-octane unleaded gasoline (91-93 octane)', TRUE),
       ('Diesel', 'Standard diesel fuel', TRUE),
       ('Biodiesel', 'Renewable diesel alternative made from plant oils', TRUE),
       ('Ethanol E85', 'High-level ethanol blend (85% ethanol, 15% gasoline)', TRUE),
       ('Electric Charging', 'EV charging station', TRUE),
       ('Natural Gas (CNG)', 'Compressed natural gas for CNG vehicles', TRUE),
       ('Propane', 'Liquefied petroleum gas (LPG)', TRUE)
ON CONFLICT (fuel_name) DO NOTHING;

-- Reset sequence
ALTER SEQUENCE temp_seq RESTART;

-- Sample data for SUPPLIER table
INSERT INTO fuel_net.supplier (supplier_name, contact_person, email, phone,
                               address, city, state_province, postal_code, country)
SELECT 'Supplier ' || nextval('temp_seq')::text                               AS supplier_name,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'John Smith'
           WHEN 1 THEN 'Maria Garcia'
           WHEN 2 THEN 'Robert Johnson'
           WHEN 3 THEN 'Lisa Chen'
           WHEN 4 THEN 'David Brown'
           WHEN 5 THEN 'Sarah Williams'
           END                                                                AS contact_person,
       'contact' || nextval('temp_seq')::text || '@supplier' || (i) || '.com' AS email,
       '555-' || LPAD((100 + nextval('temp_seq') % 900)::text, 3, '0') || '-' ||
       LPAD((1000 + nextval('temp_seq') % 9000)::text, 4, '0')                AS phone,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '100 Supply Drive'
           WHEN 1 THEN '200 Distribution Avenue'
           WHEN 2 THEN '300 Corporate Boulevard'
           WHEN 3 THEN '400 Industry Park'
           WHEN 4 THEN '500 Manufacturing Road'
           WHEN 5 THEN '600 Logistics Lane'
           END                                                                AS address,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'Dallas'
           WHEN 1 THEN 'Denver'
           WHEN 2 THEN 'Atlanta'
           WHEN 3 THEN 'Seattle'
           WHEN 4 THEN 'Boston'
           WHEN 5 THEN 'Miami'
           END                                                                AS city,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'TX'
           WHEN 1 THEN 'CO'
           WHEN 2 THEN 'GA'
           WHEN 3 THEN 'WA'
           WHEN 4 THEN 'MA'
           WHEN 5 THEN 'FL'
           END                                                                AS state_province,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '75201'
           WHEN 1 THEN '80201'
           WHEN 2 THEN '30301'
           WHEN 3 THEN '98101'
           WHEN 4 THEN '02101'
           WHEN 5 THEN '33101'
           END                                                                AS postal_code,
       'USA'                                                                  AS country
FROM generate_series(1, 8) i
ON CONFLICT (supplier_name) DO NOTHING;

-- Reset sequence
ALTER SEQUENCE temp_seq RESTART;

-- Sample data for CUSTOMER table
INSERT INTO fuel_net.customer (first_name, last_name, email, phone,
                               address, city, state_province, postal_code, country,
                               has_loyalty_card)
SELECT CASE (nextval('temp_seq') % 10)
           WHEN 0 THEN 'James'
           WHEN 1 THEN 'Jennifer'
           WHEN 2 THEN 'Michael'
           WHEN 3 THEN 'Linda'
           WHEN 4 THEN 'William'
           WHEN 5 THEN 'Elizabeth'
           WHEN 6 THEN 'David'
           WHEN 7 THEN 'Susan'
           WHEN 8 THEN 'Richard'
           WHEN 9 THEN 'Jessica'
           END                                                 AS first_name,
       CASE (nextval('temp_seq') % 10)
           WHEN 0 THEN 'Johnson'
           WHEN 1 THEN 'Smith'
           WHEN 2 THEN 'Williams'
           WHEN 3 THEN 'Jones'
           WHEN 4 THEN 'Brown'
           WHEN 5 THEN 'Davis'
           WHEN 6 THEN 'Miller'
           WHEN 7 THEN 'Wilson'
           WHEN 8 THEN 'Moore'
           WHEN 9 THEN 'Taylor'
           END                                                 AS last_name,
       'customer' || i || '@email.com'                         AS email,
       '555-' || LPAD((100 + nextval('temp_seq') % 900)::text, 3, '0') || '-' ||
       LPAD((1000 + nextval('temp_seq') % 9000)::text, 4, '0') AS phone,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '111 Residential Street'
           WHEN 1 THEN '222 Apartment Complex'
           WHEN 2 THEN '333 Suburban Drive'
           WHEN 3 THEN '444 Downtown Avenue'
           WHEN 4 THEN '555 Rural Route'
           WHEN 5 THEN '666 Townhouse Lane'
           END                                                 AS address,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'San Francisco'
           WHEN 1 THEN 'Detroit'
           WHEN 2 THEN 'San Diego'
           WHEN 3 THEN 'Columbus'
           WHEN 4 THEN 'Indianapolis'
           WHEN 5 THEN 'Charlotte'
           END                                                 AS city,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'CA'
           WHEN 1 THEN 'MI'
           WHEN 2 THEN 'CA'
           WHEN 3 THEN 'OH'
           WHEN 4 THEN 'IN'
           WHEN 5 THEN 'NC'
           END                                                 AS state_province,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '94101'
           WHEN 1 THEN '48201'
           WHEN 2 THEN '92101'
           WHEN 3 THEN '43201'
           WHEN 4 THEN '46201'
           WHEN 5 THEN '28201'
           END                                                 AS postal_code,
       'USA'                                                   AS country,
       (i % 3 = 0)                                             AS has_loyalty_card
FROM generate_series(1, 10) i
ON CONFLICT (email) DO NOTHING;

-- Get station IDs
CREATE TEMPORARY TABLE IF NOT EXISTS temp_station_ids AS
SELECT station_id
FROM fuel_net.station;

-- Sample data for EMPLOYEE table
INSERT INTO fuel_net.employee (first_name, last_name, email, phone,
                               address, city, state_province, postal_code, country,
                               hire_date, station_id, position, hourly_rate)
SELECT CASE (nextval('temp_seq') % 10)
           WHEN 0 THEN 'Robert'
           WHEN 1 THEN 'Mary'
           WHEN 2 THEN 'John'
           WHEN 3 THEN 'Patricia'
           WHEN 4 THEN 'Thomas'
           WHEN 5 THEN 'Barbara'
           WHEN 6 THEN 'Charles'
           WHEN 7 THEN 'Nancy'
           WHEN 8 THEN 'Christopher'
           WHEN 9 THEN 'Karen'
           END                                                             AS first_name,
       CASE (nextval('temp_seq') % 10)
           WHEN 0 THEN 'Anderson'
           WHEN 1 THEN 'Thompson'
           WHEN 2 THEN 'Martinez'
           WHEN 3 THEN 'Robinson'
           WHEN 4 THEN 'Clark'
           WHEN 5 THEN 'Rodriguez'
           WHEN 6 THEN 'Lewis'
           WHEN 7 THEN 'Lee'
           WHEN 8 THEN 'Walker'
           WHEN 9 THEN 'Hall'
           END                                                             AS last_name,
       'employee' || i || '@fuelnetwork.com'                               AS email,
       '555-' || LPAD((100 + nextval('temp_seq') % 900)::text, 3, '0') || '-' ||
       LPAD((1000 + nextval('temp_seq') % 9000)::text, 4, '0')             AS phone,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '777 Employee Drive'
           WHEN 1 THEN '888 Staff Road'
           WHEN 2 THEN '999 Workers Lane'
           WHEN 3 THEN '101 Team Street'
           WHEN 4 THEN '202 Personnel Avenue'
           WHEN 5 THEN '303 Associate Boulevard'
           END                                                             AS address,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'Austin'
           WHEN 1 THEN 'San Antonio'
           WHEN 2 THEN 'Memphis'
           WHEN 3 THEN 'Portland'
           WHEN 4 THEN 'Oklahoma City'
           WHEN 5 THEN 'Las Vegas'
           END                                                             AS city,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN 'TX'
           WHEN 1 THEN 'TX'
           WHEN 2 THEN 'TN'
           WHEN 3 THEN 'OR'
           WHEN 4 THEN 'OK'
           WHEN 5 THEN 'NV'
           END                                                             AS state_province,
       CASE (nextval('temp_seq') % 6)
           WHEN 0 THEN '73301'
           WHEN 1 THEN '78201'
           WHEN 2 THEN '37501'
           WHEN 3 THEN '97201'
           WHEN 4 THEN '73101'
           WHEN 5 THEN '89101'
           END                                                             AS postal_code,
       'USA'                                                               AS country,
       (CURRENT_DATE - ((nextval('temp_seq') % 730) + 30)::integer)        AS hire_date,
       (SELECT station_id FROM temp_station_ids ORDER BY random() LIMIT 1) AS station_id,
       CASE (i % 4)
           WHEN 0 THEN 'Station Manager'
           WHEN 1 THEN 'Cashier'
           WHEN 2 THEN 'Fuel Attendant'
           WHEN 3 THEN 'Maintenance'
           END                                                             AS position,
       15.00 + (nextval('temp_seq') % 25)::decimal                         AS hourly_rate
FROM generate_series(1, 12) i
ON CONFLICT (email) DO NOTHING;

-- Get fuel type IDs
CREATE TEMPORARY TABLE IF NOT EXISTS temp_fuel_type_ids AS
SELECT fuel_type_id
FROM fuel_net.fuel_type;

-- Sample data for STATION_FUEL table
INSERT INTO fuel_net.station_fuel (station_id, fuel_type_id, regular_price, discounted_price,
                                   current_quantity, capacity, is_available)
SELECT s.station_id,
       f.fuel_type_id,
       3.50 + (nextval('temp_seq') % 250)::decimal / 100 AS regular_price,
       CASE
           WHEN nextval('temp_seq') % 2 = 0
               THEN 3.40 + (nextval('temp_seq') % 250)::decimal / 100
           ELSE NULL
           END                                           AS discounted_price,
       (nextval('temp_seq') % 9000) + 1000               AS current_quantity,
       10000 + (nextval('temp_seq') % 5000)              AS capacity,
       nextval('temp_seq') % 10 > 0                      AS is_available
FROM (SELECT station_id FROM fuel_net.station) s
         CROSS JOIN
         (SELECT fuel_type_id FROM fuel_net.fuel_type WHERE fuel_type_id <= 6) f
ON CONFLICT (station_id, fuel_type_id) DO NOTHING;

-- Get supplier IDs
CREATE TEMPORARY TABLE IF NOT EXISTS temp_supplier_ids AS
SELECT supplier_id
FROM fuel_net.supplier;

CREATE TEMPORARY TABLE IF NOT EXISTS temp_count_supplier AS
SELECT (SELECT COUNT(*) FROM fuel_net.supplier) AS supplier_count;

-- Sample data for FUEL_DELIVERY table
INSERT INTO fuel_net.fuel_delivery (station_id, supplier_id, fuel_type_id, delivery_date,
                                    quantity, unit_price, total_cost, invoice_number,
                                    is_received, received_by, received_at)
SELECT sf.station_id,
       --(SELECT supplier_id FROM temp_supplier_ids ORDER BY random() LIMIT 1) AS supplier_id,
       (SELECT s.supplier_id
        FROM temp_supplier_ids s
        LIMIT 1 OFFSET (i % (SELECT supplier_count FROM temp_count_supplier)))                     AS employee_id,
       sf.fuel_type_id,
       (CURRENT_DATE - ((nextval('temp_seq') % 90))::integer)                                      AS delivery_date,
       5000 + (nextval('temp_seq') % 5000)                                                         AS quantity,
       2.50 + (nextval('temp_seq') % 150)::decimal / 100                                           AS unit_price,
       (5000 + (nextval('temp_seq') % 5000)) * (2.50 + (nextval('temp_seq') % 150)::decimal / 100) AS total_cost,
       'INV-' || to_char(CURRENT_DATE - ((nextval('temp_seq') % 90))::integer, 'YYYYMMDD') || '-' ||
       LPAD((nextval('temp_seq') % 1000)::text, 4, '0')                                            AS invoice_number,
       i < 14                                                                                      AS is_received,
       CASE
           WHEN i < 14 THEN
               CASE (nextval('temp_seq') % 5)
                   WHEN 0 THEN 'John Manager'
                   WHEN 1 THEN 'Maria Supervisor'
                   WHEN 2 THEN 'Robert Attendant'
                   WHEN 3 THEN 'Lisa Clerk'
                   WHEN 4 THEN 'David Operator'
                   END
           ELSE NULL END                                                                           AS received_by,
       CASE
           WHEN i < 14 THEN
               -- Convert date to timestamp and then add hours using interval
               (CURRENT_DATE - ((nextval('temp_seq') % 90))::integer)::timestamp +
               (((nextval('temp_seq') % 4) + 1) * interval '1 hour')
           ELSE NULL END                                                                           AS received_at
FROM fuel_net.station_fuel sf,
     generate_series(1, 18) i
WHERE i <= 18
ON CONFLICT (invoice_number) DO NOTHING;

-- Get employee IDs
CREATE TEMPORARY TABLE IF NOT EXISTS temp_employee_ids AS
SELECT employee_id
FROM fuel_net.employee;

-- Get customer IDs
CREATE TEMPORARY TABLE IF NOT EXISTS temp_customer_ids AS
SELECT customer_id
FROM fuel_net.customer;

CREATE TEMPORARY TABLE IF NOT EXISTS temp_counts AS
SELECT (SELECT COUNT(*) FROM fuel_net.customer) AS customer_count,
       (SELECT COUNT(*) FROM fuel_net.employee) AS employee_count;


-- Sample data for FUEL_SALE table
INSERT INTO fuel_net.fuel_sale (station_id, fuel_type_id, customer_id, employee_id,
                                sale_datetime, quantity_sold, unit_price, total_amount,
                                payment_method, payment_reference, loyalty_discount_applied)
SELECT sf.station_id,
       sf.fuel_type_id,
       CASE
           WHEN i % 3 < 2
               THEN (SELECT c.customer_id
                     FROM temp_customer_ids c
                     LIMIT 1 OFFSET (i % (SELECT customer_count FROM temp_counts)))
           ELSE NULL
           END                                                         AS customer_id,
--     CASE WHEN i % 3 < 2 --nextval('temp_seq') % 3 = 0
--         THEN (SELECT customer_id FROM temp_customer_ids ORDER BY random() LIMIT 1)
--         ELSE null
       -- END AS customer_id,
       (SELECT e.employee_id
        FROM temp_employee_ids e
        LIMIT 1 OFFSET (i % (SELECT employee_count FROM temp_counts))) AS employee_id,
       (CURRENT_DATE - ((nextval('temp_seq') % 90))::integer +
        ((nextval('temp_seq') % 24)::integer * 3600 +
         (nextval('temp_seq') % 60)::integer * 60 +
         (nextval('temp_seq') % 60)::integer) *
        interval '1 second')                                           AS sale_datetime,
       10 + (nextval('temp_seq') % 40)                                 AS quantity_sold,
       sf.regular_price                                                AS unit_price,
       (10 + (nextval('temp_seq') % 40)) * sf.regular_price            AS total_amount,
       CASE (nextval('temp_seq') % 3)
           WHEN 0 THEN 'CASH'
           WHEN 1 THEN 'CARD'
           WHEN 2 THEN 'LOYALTY_POINTS'
           END                                                         AS payment_method,
       CASE
           WHEN nextval('temp_seq') % 3 = 1
               THEN 'TXN-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                    LPAD((nextval('temp_seq') % 10000)::text, 6, '0')
           ELSE NULL
           END                                                         AS payment_reference,
       nextval('temp_seq') % 5 = 0                                     AS loyalty_discount_applied
FROM fuel_net.station_fuel sf,
     generate_series(1, 40) i
WHERE i <= 40
  AND sf.is_available = TRUE;


-- Drop temporary tables and sequences
DROP TABLE IF EXISTS temp_station_ids;
DROP TABLE IF EXISTS temp_fuel_type_ids;
DROP TABLE IF EXISTS temp_supplier_ids;
DROP TABLE IF EXISTS temp_employee_ids;
DROP TABLE IF EXISTS temp_customer_ids;
DROP TABLE IF EXISTS temp_count_supplier;
DROP TABLE IF EXISTS temp_count;
DROP SEQUENCE IF EXISTS temp_seq;

-- Create indexes if they don't exist
DO
$$
    BEGIN
        -- Index for station location
        IF NOT EXISTS (SELECT 1
                       FROM pg_indexes
                       WHERE indexname = 'idx_station_location'
                         AND tablename = 'station') THEN
            CREATE INDEX idx_station_location ON fuel_net.station (city, state_province, country);
        END IF;

        -- Index for fuel sale date
        IF NOT EXISTS (SELECT 1
                       FROM pg_indexes
                       WHERE indexname = 'idx_fuel_sale_date'
                         AND tablename = 'fuel_sale') THEN
            CREATE INDEX idx_fuel_sale_date ON fuel_net.fuel_sale (sale_datetime);
        END IF;

        -- Index for employee station
        IF NOT EXISTS (SELECT 1
                       FROM pg_indexes
                       WHERE indexname = 'idx_employee_station'
                         AND tablename = 'employee') THEN
            CREATE INDEX idx_employee_station ON fuel_net.employee (station_id);
        END IF;

        -- Index for station fuel availability
        IF NOT EXISTS (SELECT 1
                       FROM pg_indexes
                       WHERE indexname = 'idx_station_fuel_availability'
                         AND tablename = 'station_fuel') THEN
            CREATE INDEX idx_station_fuel_availability ON fuel_net.station_fuel (station_id, is_available);
        END IF;

        -- Index for customer loyalty
        IF NOT EXISTS (SELECT 1
                       FROM pg_indexes
                       WHERE indexname = 'idx_customer_loyalty'
                         AND tablename = 'customer') THEN
            CREATE INDEX idx_customer_loyalty ON fuel_net.customer (has_loyalty_card);
        END IF;
    END
$$;

--======================================================================================================================
-- function creation
--======================================================================================================================

--- dynamic update function that can handle updates to any table with proper validation
CREATE OR REPLACE FUNCTION fuel_net.update_table_column(
    p_table_name TEXT,
    p_primary_key_column TEXT,
    p_primary_key_value ANYELEMENT,
    p_column_name TEXT,
    p_new_value TEXT--ANYELEMENT
)
    RETURNS BOOLEAN AS
$$
DECLARE
    update_query     TEXT;
    table_exists     BOOLEAN;
    column_exists    BOOLEAN;
    pk_column_exists BOOLEAN;
    success          BOOLEAN := FALSE;
BEGIN
    -- Check if table exists
    SELECT EXISTS (SELECT
                   FROM information_schema.tables
                   WHERE table_name = p_table_name)
    INTO table_exists;

    IF NOT table_exists THEN
        RAISE EXCEPTION 'Table % does not exist', p_table_name;
    END IF;

    -- Check if primary key column exists
    SELECT EXISTS (SELECT
                   FROM information_schema.columns
                   WHERE table_name = p_table_name
                     AND column_name = p_primary_key_column)
    INTO pk_column_exists;

    IF NOT pk_column_exists THEN
        RAISE EXCEPTION 'Primary key column % does not exist in table %', p_primary_key_column, p_table_name;
    END IF;

    -- Check if column to update exists
    SELECT EXISTS (SELECT
                   FROM information_schema.columns
                   WHERE table_name = p_table_name
                     AND column_name = p_column_name)
    INTO column_exists;

    IF NOT column_exists THEN
        RAISE EXCEPTION 'Column % does not exist in table %', p_column_name, p_table_name;
    END IF;

    -- Build and execute dynamic SQL query
    update_query := format('UPDATE %I SET %I = $1 WHERE %I = $2',
                           p_table_name, p_column_name, p_primary_key_column);

    EXECUTE update_query USING p_new_value, p_primary_key_value;

    -- Check if any row was updated
    IF FOUND THEN
        success := TRUE;
    END IF;

    RETURN success;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error updating table: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Example 1: Update a station address
SELECT fuel_net.update_table_column(
               'station',
               'station_id',
               1,
               'address',
               '111 New Station address'
       );

-- Example 2: Update a customer postal code
SELECT fuel_net.update_table_column(
               'customer',
               'customer_id',
               3,
               'postal_code',
               11111
       );

--- function to add a new transaction to transaction table `fuel_sale` using natural keys for defining record fields
CREATE OR REPLACE FUNCTION fuel_net.add_fuel_sale_transaction(
    p_station_name VARCHAR(100), -- Natural key for station
    p_fuel_name VARCHAR(50), -- Natural key for fuel type
    p_customer_email VARCHAR(100), -- Natural key for customer (optional,customer csn be null)
    p_employee_email VARCHAR(100), -- Natural key for employee
    p_quantity_sold DECIMAL(10, 2),
    p_unit_price DECIMAL(10, 2),
    p_payment_method VARCHAR(50),
    p_payment_reference VARCHAR(100),
    p_loyalty_discount_applied BOOLEAN DEFAULT FALSE
)
    RETURNS TABLE
            (
                success        BOOLEAN,
                message        TEXT,
                transaction_id INTEGER
            )
AS
$$
DECLARE
    v_station_id       INTEGER;
    v_fuel_type_id     INTEGER;
    v_customer_id      INTEGER;
    v_employee_id      INTEGER;
    v_total_amount     DECIMAL(10, 2);
    v_sale_id          INTEGER;
    v_current_quantity INTEGER;
    v_is_available     BOOLEAN;
BEGIN
    -- Get station ID from station name
    SELECT station_id
    INTO v_station_id
    FROM fuel_net.station
    WHERE station_name = p_station_name;

    IF v_station_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Station not found: ' || p_station_name, NULL::INTEGER;
        RETURN;
    END IF;

    -- Get fuel type ID from fuel name
    SELECT fuel_type_id
    INTO v_fuel_type_id
    FROM fuel_net.fuel_type
    WHERE fuel_name = p_fuel_name;

    IF v_fuel_type_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Fuel type not found: ' || p_fuel_name, NULL::INTEGER;
        RETURN;
    END IF;

    -- Check if this fuel type is available at this station and has enough quantity
    SELECT current_quantity, is_available
    INTO v_current_quantity, v_is_available
    FROM fuel_net.station_fuel
    WHERE station_id = v_station_id
      AND fuel_type_id = v_fuel_type_id;

    IF v_current_quantity IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Fuel type not available at this station', NULL::INTEGER;
        RETURN;
    END IF;

    IF NOT v_is_available THEN
        RETURN QUERY SELECT FALSE, 'This fuel is currently unavailable at the station', NULL::INTEGER;
        RETURN;
    END IF;

    IF v_current_quantity < p_quantity_sold THEN
        RETURN QUERY SELECT FALSE, 'Insufficient fuel quantity available', NULL::INTEGER;
        RETURN;
    END IF;

    -- Get customer ID from email (optional, can be NULL)
    IF p_customer_email IS NOT NULL THEN
        SELECT customer_id
        INTO v_customer_id
        FROM fuel_net.customer
        WHERE email = p_customer_email;

    END IF;

    -- Get employee ID from email
    SELECT employee_id
    INTO v_employee_id
    FROM fuel_net.employee
    WHERE email = p_employee_email;

    IF v_employee_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Employee not found: ' || p_employee_email, NULL::INTEGER;
        RETURN;
    END IF;

    -- Calculate total amount
    v_total_amount := p_quantity_sold * p_unit_price;

    -- Begin transaction
    BEGIN
        -- Insert new fuel sale transaction
        INSERT INTO fuel_net.fuel_sale (station_id,
                                        fuel_type_id,
                                        customer_id,
                                        employee_id,
                                        sale_datetime,
                                        quantity_sold,
                                        unit_price,
                                        total_amount,
                                        payment_method,
                                        payment_reference,
                                        loyalty_discount_applied)
        VALUES (v_station_id,
                v_fuel_type_id,
                v_customer_id,
                v_employee_id,
                CURRENT_TIMESTAMP,
                p_quantity_sold,
                p_unit_price,
                v_total_amount,
                p_payment_method,
                p_payment_reference,
                p_loyalty_discount_applied)
        RETURNING sale_id INTO v_sale_id;

        -- Update the fuel quantity at the station
        UPDATE fuel_net.STATION_FUEL
        SET current_quantity = current_quantity - p_quantity_sold,
            last_updated     = CURRENT_TIMESTAMP
        WHERE station_id = v_station_id
          AND fuel_type_id = v_fuel_type_id;

        -- Commit transaction
        RETURN QUERY SELECT TRUE, 'Fuel sale transaction created successfully', v_sale_id;

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction
            RETURN QUERY SELECT FALSE, 'Error creating transaction: ' || SQLERRM, NULL::INTEGER;
    END;
END;
$$ LANGUAGE plpgsql;

-- Example 1: Complete transaction with all parameters
SELECT *
FROM fuel_net.add_fuel_sale_transaction(
        'Station 55',
        'Diesel',
        'customer2@email.com',
        'employee2@fuelnetwork.com',
        25.5,
        3.75,
        'CARD',
        'TXN-2025-04-25-001',
        TRUE
     );

-- Example 2: Transaction without customer (anonymous purchase)
SELECT *
FROM fuel_net.add_fuel_sale_transaction(
        'Station 19',
        'Regular Gasoline',
        NULL, -- no customer (anonymous)
        'employee3@fuelnetwork.com',
        15.0,
        4.25,
        'CASH',
        NULL,
        FALSE
     );
--======================================================================================================================
-- view creation
--======================================================================================================================
/*
* View: fuel_net.station_quarterly_performance
*
* Purpose:
* This view provides a consolidated analysis of station performance metrics for the most recently
* completed quarter. It identifies key performance indicators including sales volume, revenue,
* delivery costs, and profitability across all stations and fuel types. The view is designed to help
* management quickly identify top and underperforming stations, analyze profit margins by fuel type,
* and track quarterly business trends without needing to join multiple tables manually.
*
* Business Value:
* - Enables quick identification of best/worst performing stations and fuel products
* - Provides insights on customer engagement through average spend and frequency
* - Offers visibility into operational efficiency via sales velocity metrics
* - Supports data-driven decision making for inventory management and pricing strategy
*/

CREATE OR REPLACE VIEW fuel_net.station_quarterly_performance AS
WITH current_quarter AS (
    -- Identify the most recent quarter in the database based on fuel sales
    SELECT
        EXTRACT(YEAR FROM sale_datetime) AS year,
        EXTRACT(QUARTER FROM sale_datetime) AS quarter
    FROM fuel_net.fuel_sale
    ORDER BY year DESC, quarter DESC
    LIMIT 1
),

quarterly_sales AS (
    -- Get all sales from the most recent quarter
    SELECT
        fs.station_id,
        s.station_name,
        s.city,
        s.state_province,
        ft.fuel_name,
        SUM(fs.quantity_sold) AS total_quantity_sold,
        SUM(fs.total_amount) AS total_revenue,
        COUNT(DISTINCT fs.customer_id) AS unique_customers,
        COUNT(*) AS transaction_count,
        AVG(fs.unit_price) AS avg_unit_price
    FROM fuel_net.fuel_sale fs
    JOIN fuel_net.station s ON fs.station_id = s.station_id
    JOIN fuel_net.fuel_type ft ON fs.fuel_type_id = ft.fuel_type_id
    JOIN current_quarter cq ON
        EXTRACT(YEAR FROM fs.sale_datetime) = cq.year AND
        EXTRACT(QUARTER FROM fs.sale_datetime) = cq.quarter
    GROUP BY
        fs.station_id,
        s.station_name,
        s.city,
        s.state_province,
        ft.fuel_name
),

quarterly_delivery AS (
    -- Get all deliveries from the most recent quarter
    SELECT
        fd.station_id,
        ft.fuel_name,
        SUM(fd.quantity) AS total_delivery_quantity,
        SUM(fd.total_cost) AS total_delivery_cost,
        COUNT(*) AS delivery_count
    FROM fuel_net.fuel_delivery fd
    JOIN fuel_net.fuel_type ft ON fd.fuel_type_id = ft.fuel_type_id
    JOIN current_quarter cq ON
        EXTRACT(YEAR FROM fd.delivery_date) = cq.year AND
        EXTRACT(QUARTER FROM fd.delivery_date) = cq.quarter
    WHERE fd.is_received = TRUE
    GROUP BY
        fd.station_id,
        ft.fuel_name
)

-- Final view combining sales and delivery data
SELECT
    qs.station_id,
    qs.station_name,
    qs.city,
    qs.state_province,
    qs.fuel_name,
    EXTRACT(YEAR FROM CURRENT_DATE) AS year,
    EXTRACT(QUARTER FROM CURRENT_DATE) AS quarter,

    -- Sales metrics
    qs.total_quantity_sold,
    qs.total_revenue,
    qs.unique_customers,
    qs.transaction_count,
    qs.avg_unit_price,

    -- Delivery metrics
    COALESCE(qd.total_delivery_quantity, 0) AS total_delivery_quantity,
    COALESCE(qd.total_delivery_cost, 0) AS total_delivery_cost,
    COALESCE(qd.delivery_count, 0) AS delivery_count,

    -- Performance calculations
    COALESCE(qs.total_revenue - qd.total_delivery_cost, qs.total_revenue) AS gross_profit,
    CASE
        WHEN qd.total_delivery_cost > 0 THEN
            ROUND(((qs.total_revenue - qd.total_delivery_cost) / qd.total_delivery_cost) * 100, 2)
        ELSE NULL
    END AS profit_margin_percentage,

    -- Sales velocity
    ROUND(qs.total_quantity_sold / GREATEST(qd.delivery_count, 1), 2) AS sales_per_delivery,

    -- Customer metrics
    ROUND(qs.total_revenue / GREATEST(qs.unique_customers, 1), 2) AS revenue_per_customer,

    -- Current date for reference
    CURRENT_TIMESTAMP AS report_generated_at
FROM quarterly_sales qs
LEFT JOIN quarterly_delivery qd ON
    qs.station_id = qd.station_id AND
    qs.fuel_name = qd.fuel_name
ORDER BY
    gross_profit DESC,
    qs.station_id,
    qs.fuel_name;

--Example of usage
    SELECT * FROM fuel_net.station_quarterly_performance;

-- quarterly performance for stations in New York city for selling diesel fuel
SELECT * FROM fuel_net.station_quarterly_performance
WHERE city = 'New York' AND fuel_name = 'Diesel';

--======================================================================================================================
-- DB role management
--======================================================================================================================
-- Create the manager role with login capability
CREATE ROLE fuel_manager WITH
    LOGIN
    PASSWORD 'qwerty123'
    CONNECTION LIMIT 5 -- Limit concurrent connections
    VALID UNTIL '2026-04-25'; -- Set expiration (should be updated periodically)

-- Add comment to the role for documentation
COMMENT ON ROLE fuel_manager IS 'Read-only role for fuel station managers';

-- Grant schema usage permission
GRANT USAGE ON SCHEMA fuel_net TO fuel_manager;

-- Grant SELECT permission on all existing tables in the fuel_net schema
GRANT SELECT ON ALL TABLES IN SCHEMA fuel_net TO fuel_manager;

-- Grant SELECT permission on the analytics views
GRANT SELECT ON fuel_net.station_quarterly_performance TO fuel_manager;


-- Revoke public schema permissions (security best practice)
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE fuel_network_db FROM PUBLIC;

--Example of usage
SET ROLE fuel_manager;
SELECT current_user;

-- View resent sales
SELECT * FROM fuel_net.FUEL_SALE ORDER BY sale_datetime DESC LIMIT 100;

-- View station performance
SELECT * FROM fuel_net.station_quarterly_performance;
