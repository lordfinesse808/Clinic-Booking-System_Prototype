-- Clinic Booking System Database Script (Updated with Sample Data and Advanced Features)
-- Date: October 16, 2025
-- Description: This SQL script creates a complete relational database for a Clinic Booking System.
--              It manages patients, doctors, specialties, clinics, appointments, and medical records.
--              The system supports one-to-one (e.g., patient details), one-to-many (e.g., doctor to appointments),
--              and many-to-many (e.g., doctors to specialties and clinics) relationships.
--              This is designed for a fictional clinic network called "HealthHub Clinics" that allows patients
--              to book appointments with specialized doctors across multiple locations.
--
-- Updates in this Version:
-- - Added sample INSERT statements to populate the database with fictional data for testing.
-- - Advanced Features:
--   - TRIGGER: Automatically updates a 'last_updated' timestamp on patients table for audit purposes.
--   - VIEW: Creates a view for upcoming appointments to easily query scheduled bookings.
--   - STORED PROCEDURE: For booking a new appointment, including basic validation (e.g., check if slot is free).
--   - INDEXES: Added more for performance on common query fields.
--   - USER and PRIVILEGES: Creates a dedicated user for the application with limited privileges for security.
--
-- Instructions for Beginners (Zero to Hero MySQL Guide):
-- 1. What is MySQL? MySQL is a popular open-source relational database management system (RDBMS) used to store,
--    organize, and retrieve data in a structured way using tables, rows, and columns.
-- 2. Running this Script: Install MySQL (e.g., via MySQL Community Server). Use a tool like MySQL Workbench,
--    phpMyAdmin, or the MySQL command-line client. Log in as root or a user with CREATE privileges.
--    Copy-paste this entire script into the query editor and execute it. It will create the database and tables.
-- 3. Key Concepts:
--    - DATABASE: A container for tables and data.
--    - TABLE: Like a spreadsheet, with columns (fields) and rows (records).
--    - PRIMARY KEY: Unique identifier for each row, often auto-incrementing.
--    - FOREIGN KEY: Links tables, enforcing relationships and data integrity.
--    - CONSTRAINTS: Rules like NOT NULL (must have value), UNIQUE (no duplicates).
--    - ENUM: Limits column values to a predefined set.
--    - AUTO_INCREMENT: Automatically generates unique IDs.
--    - ON DELETE CASCADE: If a parent row is deleted, child rows are auto-deleted.
--    - TRIGGER: Automated action on events like INSERT/UPDATE/DELETE.
--    - VIEW: Virtual table based on a query, for simplified access.
--    - STORED PROCEDURE: Reusable SQL code block, like a function, for complex operations.
-- 4. Why this Design? It's normalized (reduces redundancy), scalable, and covers real-world needs like preventing
--    double-bookings for doctors and handling multiple specialties per doctor.
-- 5. After Creation: You can insert data with INSERT statements, query with SELECT, update with UPDATE, etc.
--    Example: INSERT INTO patients (first_name, last_name, dob, gender, phone) VALUES ('John', 'Doe', '1990-01-01', 'Male', '1234567890');
-- 6. Testing: After running, use SHOW DATABASES; to see 'clinic_booking'. Use DESCRIBE patients; to view table structure.
--    Call the stored procedure: CALL book_appointment(1, 1, 1, '2025-11-01', '10:00:00', 'Initial checkup');
-- 7. Advanced Tips: Use indexes for faster queries (added here where needed). Backup your DB with mysqldump.
--    For production, use the created user: clinic_app_user with password 'securepass'.

-- Step 1: Create the Database
-- Explanation: This creates a new database named 'clinic_booking'. If it exists, we drop it first to start fresh.
--              USE statement selects it for subsequent queries.
DROP DATABASE IF EXISTS clinic_booking;
CREATE DATABASE clinic_booking;
USE clinic_booking;

-- Step 2: Create Tables
-- Explanation: Each CREATE TABLE defines a table with columns, data types, and constraints.
--              Data Types: INT (integer), VARCHAR (variable-length string), DATE (YYYY-MM-DD), TIME (HH:MM:SS),
--              ENUM (restricted values), TEXT (long text), TIMESTAMP (date/time).

-- Table: patients
-- Added: last_updated for tracking changes.
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table: clinics
CREATE TABLE clinics (
    clinic_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: specialties
CREATE TABLE specialties (
    specialty_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Table: doctors
-- Added: last_updated for tracking.
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table: doctor_specialties (Many-to-Many)
CREATE TABLE doctor_specialties (
    doctor_id INT NOT NULL,
    specialty_id INT NOT NULL,
    PRIMARY KEY (doctor_id, specialty_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON DELETE CASCADE
);

-- Table: doctor_clinics (Many-to-Many)
CREATE TABLE doctor_clinics (
    doctor_id INT NOT NULL,
    clinic_id INT NOT NULL,
    PRIMARY KEY (doctor_id, clinic_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE
);

-- Table: appointments
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    clinic_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-Show') DEFAULT 'Scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE,
    UNIQUE KEY unique_booking (doctor_id, appointment_date, appointment_time)
);

-- Table: medical_records
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    diagnosis TEXT,
    prescription TEXT,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
);

-- Step 3: Additional Indexes (For Performance)
-- Explanation: Indexes speed up queries on frequently searched columns.
-- Reason: Improves SELECT performance for emails, phones, dates, etc., which are common in searches.
CREATE INDEX idx_patient_email ON patients(email);
CREATE INDEX idx_patient_phone ON patients(phone);
CREATE INDEX idx_doctor_email ON doctors(email);
CREATE INDEX idx_doctor_phone ON doctors(phone);
CREATE INDEX idx_appointment_date ON appointments(appointment_date);
CREATE INDEX idx_appointment_status ON appointments(status);

-- Step 4: Triggers
-- Explanation: Triggers are automatic SQL code that runs before/after events.
-- Reason: Ensures data consistency, e.g., auto-updating timestamps without app logic.
-- Trigger: Update last_updated on patients before any update.
DELIMITER //
CREATE TRIGGER update_patient_timestamp
BEFORE UPDATE ON patients
FOR EACH ROW
BEGIN
    SET NEW.last_updated = CURRENT_TIMESTAMP;
END;
//
DELIMITER ;

-- Similar trigger for doctors.
DELIMITER //
CREATE TRIGGER update_doctor_timestamp
BEFORE UPDATE ON doctors
FOR EACH ROW
BEGIN
    SET NEW.last_updated = CURRENT_TIMESTAMP;
END;
//
DELIMITER ;

-- Step 5: Views
-- Explanation: Views are stored queries that act like virtual tables.
-- Reason: Simplifies complex queries for the application, e.g., joining tables for reports.
-- View: upcoming_appointments - Shows scheduled appointments in the future.
CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    p.first_name AS patient_first,
    p.last_name AS patient_last,
    d.first_name AS doctor_first,
    d.last_name AS doctor_last,
    c.name AS clinic_name,
    a.appointment_date,
    a.appointment_time,
    a.notes
FROM 
    appointments a
JOIN 
    patients p ON a.patient_id = p.patient_id
JOIN 
    doctors d ON a.doctor_id = d.doctor_id
JOIN 
    clinics c ON a.clinic_id = c.clinic_id
WHERE 
    a.status = 'Scheduled' AND CONCAT(a.appointment_date, ' ', a.appointment_time) > NOW();

-- Step 6: Stored Procedures
-- Explanation: Stored procedures are reusable SQL blocks for complex logic.
-- Reason: Encapsulates business logic in DB (e.g., validation), reduces app-DB roundtrips, improves security.
-- Procedure: book_appointment - Inserts a new appointment after checking if the slot is free.
DELIMITER //
CREATE PROCEDURE book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_clinic_id INT,
    IN p_date DATE,
    IN p_time TIME,
    IN p_notes TEXT
)
BEGIN
    DECLARE slot_count INT;
    
    -- Check if slot is already booked (leverages UNIQUE constraint but adds explicit check)
    SELECT COUNT(*) INTO slot_count
    FROM appointments
    WHERE doctor_id = p_doctor_id AND appointment_date = p_date AND appointment_time = p_time;
    
    IF slot_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment slot is already booked.';
    ELSE
        INSERT INTO appointments (patient_id, doctor_id, clinic_id, appointment_date, appointment_time, notes)
        VALUES (p_patient_id, p_doctor_id, p_clinic_id, p_date, p_time, p_notes);
    END IF;
END;
//
DELIMITER ;

-- Step 7: Sample Data INSERTs
-- Explanation: INSERT statements add fictional sample data for testing.
-- Reason: Allows immediate testing of queries, views, procedures without empty tables.
-- Insert Clinics
INSERT INTO clinics (name, address, phone) VALUES 
('HealthHub Downtown', '123 Main St, Cityville', '555-0101'),
('HealthHub Uptown', '456 Elm St, Townsville', '555-0102');

-- Insert Specialties
INSERT INTO specialties (name, description) VALUES 
('Cardiology', 'Heart-related issues'),
('Pediatrics', 'Child health'),
('Dermatology', 'Skin conditions');

-- Insert Doctors
INSERT INTO doctors (first_name, last_name, phone, email, bio) VALUES 
('Alice', 'Smith', '555-1001', 'alice.smith@healthhub.com', 'Experienced cardiologist'),
('Bob', 'Johnson', '555-1002', 'bob.johnson@healthhub.com', 'Pediatric specialist'),
('Carol', 'Davis', '555-1003', 'carol.davis@healthhub.com', 'Dermatologist');

-- Insert Doctor-Specialties (Many-to-Many)
INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES 
(1, 1),  -- Alice: Cardiology
(2, 2),  -- Bob: Pediatrics
(3, 3),  -- Carol: Dermatology
(1, 2);  -- Alice also Pediatrics

-- Insert Doctor-Clinics (Many-to-Many)
INSERT INTO doctor_clinics (doctor_id, clinic_id) VALUES 
(1, 1), (1, 2),  -- Alice at both
(2, 1),         -- Bob at Downtown
(3, 2);         -- Carol at Uptown

-- Insert Patients
INSERT INTO patients (first_name, last_name, dob, gender, phone, email, address) VALUES 
('John', 'Doe', '1990-05-15', 'Male', '555-2001', 'john.doe@email.com', '789 Oak St'),
('Jane', 'Roe', '1985-08-20', 'Female', '555-2002', 'jane.roe@email.com', '101 Pine St'),
('Sam', 'Lee', '2000-01-10', 'Other', '555-2003', 'sam.lee@email.com', '202 Maple St');

-- Insert Appointments
INSERT INTO appointments (patient_id, doctor_id, clinic_id, appointment_date, appointment_time, notes) VALUES 
(1, 1, 1, '2025-11-01', '10:00:00', 'Routine checkup'),
(2, 2, 1, '2025-11-02', '11:00:00', 'Vaccination'),
(3, 3, 2, '2025-11-03', '14:00:00', 'Skin consultation');

-- Insert Medical Records (for completed appointments, but since samples are future, add one hypothetical)
UPDATE appointments SET status = 'Completed' WHERE appointment_id = 1;
INSERT INTO medical_records (appointment_id, diagnosis, prescription, follow_up_date) VALUES 
(1, 'Normal heart rhythm', 'Aspirin daily', '2026-05-01');

-- Step 8: Create Application User
-- Explanation: Creates a user with limited privileges.
-- Reason: Security best practice - app connects with least privileges, not root.
CREATE USER IF NOT EXISTS 'clinic_app_user'@'localhost' IDENTIFIED BY 'securepass';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON clinic_booking.* TO 'clinic_app_user'@'localhost';
FLUSH PRIVILEGES;

-- End of Script
-- To Deploy: Save this as 'clinic_booking.sql' and run: mysql -u root -p < clinic_booking.sql
-- Next Steps: Connect from FastAPI app using user 'clinic_app_user' and password 'securepass'.
-- Example Query: SELECT * FROM upcoming_appointments;
-- Call Procedure: CALL book_appointment(1, 1, 1, '2025-11-05', '15:00:00', 'Follow-up');
