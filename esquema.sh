#!/bin/bash

# Crear archivo .env
cat > .env <<EOL
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=fastapi_db
POSTGRES_HOST=db
POSTGRES_PORT=5432

# FastAPI
APP_HOST=0.0.0.0
APP_PORT=8000
EOL

# Crear docker-compose.yml
cat > docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: postgres:13
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  app:
    build: .
    env_file:
      - .env
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    command: bash -c "alembic upgrade head && uvicorn app.main:app --host \$\$APP_HOST --port \$\$APP_PORT --reload"

volumes:
  postgres_data:
EOL

# Crear Dockerfile
cat > Dockerfile <<EOL
FROM python:3.9

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
EOL

# Crear requirements.txt
cat > requirements.txt <<EOL
fastapi==0.95.2
uvicorn==0.22.0
sqlalchemy==2.0.15
psycopg2-binary==2.9.6
alembic==1.11.1
python-dotenv==1.0.0
EOL

# Crear alembic.ini
cat > alembic.ini <<EOL
[alembic]
script_location = app/alembic
sqlalchemy.url = postgresql+psycopg2://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOL

# Crear archivos dentro de app/
cd app

# __init__.py
touch __init__.py

# database.py
cat > database.py <<EOL
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

SQLALCHEMY_DATABASE_URL = f"postgresql+psycopg2://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
EOL

# models.py
cat > models.py <<EOL
from sqlalchemy import Column, Integer, String
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
EOL

# main.py
cat > main.py <<EOL
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models
from .database import engine, SessionLocal

app = FastAPI()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"Hello": "World"}

# Aquí puedes agregar más endpoints
EOL

# Configurar alembic/env.py
cd alembic
cat > env.py <<EOL
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
import os
from dotenv import load_dotenv
import sys

# Agregar el directorio app al path
sys.path.append(os.getcwd())

from app.database import Base
from app.models import User  # Importa todos tus modelos aquí

load_dotenv()

# Esto es el objeto MetaData de SQLAlchemy para soporte de autogeneración
target_metadata = Base.metadata

def run_migrations_offline() -> None:
    url = context.config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    connectable = engine_from_config(
        context.config.get_section(context.config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
EOL

# Crear script.py.mako
cat > script.py.mako <<EOL
"""\${message}

Revision ID: \${up_revision}
Revises: \${down_revision | comma,n}
Create Date: \${create_date}

"""
from alembic import op
import sqlalchemy as sa
\${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = \${repr(up_revision)}
down_revision = \${repr(down_revision)}
branch_labels = \${repr(branch_labels)}
depends_on = \${repr(depends_on)}


def upgrade():
    \${upgrades if upgrades else "pass"}


def downgrade():
    \${downgrades if downgrades else "pass"}
EOL

echo "Estructura del proyecto creada exitosamente!"
echo "Ahora puedes ejecutar:"
echo "1. docker-compose run app alembic init app/alembic"
echo "2. docker-compose up --build"