CRUD
# main.py - FastAPI CRUD Application for Clinic Booking System


# Explanation: FastAPI is a modern, fast (high-performance) web framework for building APIs with Python 3.7+ based on standard Python type hints.
# Reason: Chosen for its speed, automatic interactive API documentation (Swagger UI), async support, and easy integration with databases.
# Concepts:
# - ASGI: Asynchronous Server Gateway Interface - Allows async operations for better performance.
# - Pydantic: Used for data validation and settings management via models.
# - SQLAlchemy: ORM (Object-Relational Mapping) for database interactions - Abstracts SQL queries into Python objects.
# - Reason for SQLAlchemy: Simplifies CRUD with Python code, handles relationships, supports async for non-blocking I/O.
# - Dependencies: uvicorn (ASGI server), mysqlclient or pymysql (MySQL driver).
# - Advanced Features:
#   - Async CRUD: Uses async/await for database operations to handle concurrency.
#   - Pagination: Limits and offsets for reading large datasets.
#   - Error Handling: Custom HTTP exceptions for better API responses.
#   - Authentication: Basic JWT-based auth to secure endpoints (using fastapi-jwt-auth or similar, but here simple HTTPBasic for demo).
#   - Dependency Injection: Uses FastAPI's Depends for reusable code (e.g., get_db).
#   - API Documentation: Auto-generated via /docs.
# - Schema: Connects to the existing MySQL database 'clinic_booking'.
# - Entities: CRUD for Patients and Appointments (two entities as required).


from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from sqlalchemy import create_engine, Column, Integer, String, Date, Enum, Text, ForeignKey, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.future import select
from sqlalchemy.sql import func
from pydantic import BaseModel
from typing import List, Optional
import enum
import asyncio
from datetime import date, time, datetime


# Database Connection
# Explanation: Uses async engine for non-blocking DB calls.
# Reason: Improves scalability for I/O-bound operations like DB queries.
DATABASE_URL = "mysql+aiomysql://clinic_app_user:securepass@localhost/clinic_booking"  # aiomysql for async MySQL
engine = create_async_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, class_=AsyncSession)
Base = declarative_base()


# Models (SQLAlchemy ORM)
# Explanation: Python classes mapping to DB tables.
# Reason: Allows object-oriented interaction with DB.
class GenderEnum(enum.Enum):
    Male = "Male"
    Female = "Female"
    Other = "Other"


class StatusEnum(enum.Enum):
    Scheduled = "Scheduled"
    Completed = "Completed"
    Cancelled = "Cancelled"
    No_Show = "No-Show"


class Patient(Base):
    __tablename__ = "patients"
    patient_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    dob = Column(Date, nullable=False)
    gender = Column(Enum(GenderEnum), nullable=False)
    phone = Column(String(15), unique=True, nullable=False)
    email = Column(String(100), unique=True)
    address = Column(Text)
    created_at = Column(DateTime, server_default=func.now())
    last_updated = Column(DateTime, server_default=func.now(), onupdate=func.now())


class Appointment(Base):
    __tablename__ = "appointments"
    appointment_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(Integer, ForeignKey("patients.patient_id", ondelete="CASCADE"), nullable=False)
    doctor_id = Column(Integer, nullable=False)  # Assuming doctor/clinic exist, no FK for simplicity in demo
    clinic_id = Column(Integer, nullable=False)
    appointment_date = Column(Date, nullable=False)
    appointment_time = Column(String(8), nullable=False)  # TIME as string for simplicity
    status = Column(Enum(StatusEnum), default=StatusEnum.Scheduled)
    notes = Column(Text)
    created_at = Column(DateTime, server_default=func.now())
    patient = relationship("Patient", back_populates="appointments") if not hasattr(Patient, 'appointments') else None


if not hasattr(Patient, 'appointments'):
    Patient.appointments = relationship("Appointment", back_populates="patient")


# Pydantic Models for API
# Explanation: Data validation models for requests/responses.
# Reason: Ensures type safety, auto-serialization to JSON.
class PatientBase(BaseModel):
    first_name: str
    last_name: str
    dob: date
    gender: GenderEnum
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None


class PatientCreate(PatientBase):
    pass


class PatientResponse(PatientBase):
    patient_id: int
    created_at: datetime
    last_updated: datetime


    class Config:
        from_attributes = True  # For ORM mode


class AppointmentBase(BaseModel):
    patient_id: int
    doctor_id: int
    clinic_id: int
    appointment_date: date
    appointment_time: str  # HH:MM:SS
    notes: Optional[str] = None


class AppointmentCreate(AppointmentBase):
    pass


class AppointmentResponse(AppointmentBase):
    appointment_id: int
    status: StatusEnum
    created_at: datetime


    class Config:
        from_attributes = True


# FastAPI App
app = FastAPI(title="Clinic Booking CRUD API")


# Dependency: Get DB Session
# Explanation: Async session for each request.
# Reason: Ensures DB connection is properly managed and closed.
async def get_db():
    async with SessionLocal() as session:
        yield session


# Basic Auth (for demo)
# Explanation: Simple HTTP Basic Auth.
# Reason: Adds security layer; in production, use JWT or OAuth.
security = HTTPBasic()


def verify_credentials(credentials: HTTPBasicCredentials = Depends(security)):
    if credentials.username != "admin" or credentials.password != "secret":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username


# CRUD for Patients
@app.post("/patients/", response_model=PatientResponse, status_code=201)
async def create_patient(patient: PatientCreate, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    # Explanation: Creates a new patient.
    # Reason: POST for creation, returns 201 Created.
    db_patient = Patient(**patient.dict())
    db.add(db_patient)
    await db.commit()
    await db.refresh(db_patient)
    return db_patient


@app.get("/patients/", response_model=List[PatientResponse])
async def read_patients(skip: int = 0, limit: int = 10, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    # Explanation: Reads patients with pagination.
    # Reason: GET for reading, pagination prevents loading all data at once.
    result = await db.execute(select(Patient).offset(skip).limit(limit))
    patients = result.scalars().all()
    if not patients:
        raise HTTPException(status_code=404, detail="No patients found")
    return patients


@app.get("/patients/{patient_id}", response_model=PatientResponse)
async def read_patient(patient_id: int, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    result = await db.execute(select(Patient).where(Patient.patient_id == patient_id))
    patient = result.scalar_one_or_none()
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@app.put("/patients/{patient_id}", response_model=PatientResponse)
async def update_patient(patient_id: int, patient: PatientCreate, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    # Explanation: Updates existing patient.
    # Reason: PUT for full update.
    result = await db.execute(select(Patient).where(Patient.patient_id == patient_id))
    db_patient = result.scalar_one_or_none()
    if db_patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    for key, value in patient.dict().items():
        setattr(db_patient, key, value)
    await db.commit()
    await db.refresh(db_patient)
    return db_patient


@app.delete("/patients/{patient_id}", status_code=204)
async def delete_patient(patient_id: int, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    # Explanation: Deletes patient (cascades due to FK).
    # Reason: DELETE for removal, 204 No Content on success.
    result = await db.execute(select(Patient).where(Patient.patient_id == patient_id))
    db_patient = result.scalar_one_or_none()
    if db_patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    await db.delete(db_patient)
    await db.commit()
    return None


# CRUD for Appointments
@app.post("/appointments/", response_model=AppointmentResponse, status_code=201)
async def create_appointment(appointment: AppointmentCreate, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    db_appointment = Appointment(**appointment.dict())
    db.add(db_appointment)
    try:
        await db.commit()
        await db.refresh(db_appointment)
    except Exception as e:  # Catch integrity errors, e.g., unique constraint
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    return db_appointment


@app.get("/appointments/", response_model=List[AppointmentResponse])
async def read_appointments(skip: int = 0, limit: int = 10, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    result = await db.execute(select(Appointment).offset(skip).limit(limit))
    appointments = result.scalars().all()
    if not appointments:
        raise HTTPException(status_code=404, detail="No appointments found")
    return appointments


@app.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
async def read_appointment(appointment_id: int, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    result = await db.execute(select(Appointment).where(Appointment.appointment_id == appointment_id))
    appointment = result.scalar_one_or_none()
    if appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return appointment


@app.put("/appointments/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(appointment_id: int, appointment: AppointmentCreate, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    result = await db.execute(select(Appointment).where(Appointment.appointment_id == appointment_id))
    db_appointment = result.scalar_one_or_none()
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    for key, value in appointment.dict().items():
        setattr(db_appointment, key, value)
    await db.commit()
    await db.refresh(db_appointment)
    return db_appointment


@app.delete("/appointments/{appointment_id}", status_code=204)
async def delete_appointment(appointment_id: int, db: AsyncSession = Depends(get_db), username: str = Depends(verify_credentials)):
    result = await db.execute(select(Appointment).where(Appointment.appointment_id == appointment_id))
    db_appointment = result.scalar_one_or_none()
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    await db.delete(db_appointment)
    await db.commit()
    return None


# Run the app (for development)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)




