# Clinic-Booking-System_Prototype
Clinic Booking System database and FASTAPI integration
README
Clinic Booking CRUD API - README.md


## Project Overview
This is a simple CRUD application built with FastAPI that interacts with the MySQL database for the Clinic Booking System. It provides API endpoints for managing Patients and Appointments. Advanced features include async database operations, pagination, basic authentication, and error handling.


## Prerequisites
- Python 3.7+
- MySQL server with the `clinic_booking` database created (from the provided .sql script).
- Database user: `clinic_app_user` with password `securepass` (as created in the SQL script).


## Installation
1. Create a virtual environment:
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
text
2. Install dependencies:
pip install fastapi uvicorn sqlalchemy pydantic aiomysql
text
3. Ensure the database is running and populated (run the .sql script if not already).


## How to Run
1. Save the FastAPI code as `main.py`.
2. Run the server:
uvicorn main:app --reload
text
- Access the API at `http://127.0.0.1:8000`.
- Interactive docs at `http://127.0.0.1:8000/docs` (use username: `admin`, password: `secret` for auth).


## API Endpoints
All endpoints require Basic Authentication (username: `admin`, password: `secret`).


### Patients
- **POST /patients/**: Create a new patient.
- Body: JSON with `first_name`, `last_name`, `dob` (YYYY-MM-DD), `gender` (Male/Female/Other), `phone`, `email` (optional), `address` (optional).
- Response: 201 Created with patient details.


- **GET /patients/**: Read patients (paginated).
- Query Params: `skip` (default 0), `limit` (default 10).
- Response: List of patients.


- **GET /patients/{patient_id}**: Read a specific patient.
- Response: Patient details or 404 if not found.


- **PUT /patients/{patient_id}**: Update a patient.
- Body: Same as create.
- Response: Updated patient or 404.


- **DELETE /patients/{patient_id}**: Delete a patient.
- Response: 204 No Content or 404.


### Appointments
- **POST /appointments/**: Create a new appointment.
- Body: JSON with `patient_id`, `doctor_id`, `clinic_id`, `appointment_date` (YYYY-MM-DD), `appointment_time` (HH:MM:SS), `notes` (optional).
- Response: 201 Created or 400 if slot booked (due to unique constraint).


- **GET /appointments/**: Read appointments (paginated).
- Query Params: `skip` (default 0), `limit` (default 10).
- Response: List of appointments.


- **GET /appointments/{appointment_id}**: Read a specific appointment.
- Response: Appointment details or 404.


- **PUT /appointments/{appointment_id}**: Update an appointment.
- Body: Same as create.
- Response: Updated appointment or 404.


- **DELETE /appointments/{appointment_id}**: Delete an appointment.
- Response: 204 No Content or 404.


## Notes
- This is a prototype; in production, use environment variables for secrets, add more validation, and consider full JWT auth.
- Error handling: Returns meaningful HTTP errors.
- Testing: Use tools like Postman or the Swagger UI for auth and requests.
