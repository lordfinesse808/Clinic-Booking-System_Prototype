-- Clinic Booking System Database Script 
-- Description: This SQL script creates a complete relational database for a Clinic Booking System.
--              It manages patients, doctors, specialties, clinics, appointments, and medical records.
--              It's is designed for a fictional clinic network called "HealthHub Clinics" that allows patients
--              to book appointments with specialized doctors across multiple locations.
--

-- 2. Running this Script: Install MySQL (e.g., via MySQL Community Server). Use a tool like MySQL Workbench, use the created user: clinic_app_user with password 'securepass'.

-- Step 1: Create the Database
DROP DATABASE IF EXISTS clinic_booking;
CREATE DATABASE clinic_booking;
USE clinic_booking;

-- Step 2: Create Tables
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

-- Table: doctor_specialties 
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

CREATE INDEX idx_patient_email ON patients(email);
CREATE INDEX idx_patient_phone ON patients(phone);
CREATE INDEX idx_doctor_email ON doctors(email);
CREATE INDEX idx_doctor_phone ON doctors(phone);
CREATE INDEX idx_appointment_date ON appointments(appointment_date);
CREATE INDEX idx_appointment_status ON appointments(status);

-- Step 4: Triggers
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
    
    Check if slot is already booked 
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

-- Step 7:Test Data INSERTs
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

-- Insert Doctor-Specialties 
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

-- Insert Medical Records (for completed appointments)
UPDATE appointments SET status = 'Completed' WHERE appointment_id = 1;
INSERT INTO medical_records (appointment_id, diagnosis, prescription, follow_up_date) VALUES 
(1, 'Normal heart rhythm', 'Aspirin daily', '2026-05-01');

-- Step 8: Create Application User
CREATE USER IF NOT EXISTS 'clinic_app_user'@'localhost' IDENTIFIED BY 'securepass';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON clinic_booking.* TO 'clinic_app_user'@'localhost';
FLUSH PRIVILEGES;

-- End of Script
-- To Deploy: Save this as 'clinic_booking.sql' and run: mysql -u root -p < clinic_booking.sql

