# FastAPI + PostgreSQL + SQLAlchemy + Alembic + Docker

Este proyecto es una plantilla básica para crear una API RESTful utilizando **FastAPI** y una base de datos **PostgreSQL**, con contenedores de **Docker**. Además, se utiliza **SQLAlchemy** como ORM y **Alembic** para la gestión de migraciones de la base de datos.

---

## Tecnologías utilizadas

- [FastAPI](https://fastapi.tiangolo.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [SQLAlchemy](https://www.sqlalchemy.org/)
- [Alembic](https://alembic.sqlalchemy.org/)
- [Docker & Docker Compose](https://www.docker.com/)

## ¿Qué pretende este mini proyecto?

Este proyecto tiene como objetivo servir como base para desarrollos más complejos en FastAPI con una base de datos relacional. Además, pretende profundizar en el sistema de migraciones mediante Alembic, permitiendo crear y modificar tablas en la base de datos de forma fácil, controlada e intuitiva.

### Objetivos principales:

- **Sentar las bases para una instalación desde Docker** de una API construida con FastAPI, conectada a una base de datos PostgreSQL.
- **Probar el correcto funcionamiento del entorno**: desde la construcción de imágenes y ejecución de contenedores hasta la conexión y persistencia de datos en la base de datos.
- **Visualizar y entender las configuraciones necesarias** en los distintos ficheros clave:
  - `docker-compose.yml`: definición y coordinación de los servicios (API y base de datos).
  - `init.py`: creación de tablas e inserción de datos iniciales mediante SQLAlchemy.
  - `requirements.txt`: declaración de dependencias del entorno Python.
  - `alembic.ini`: configuración del sistema de migraciones Alembic.
  - `env.py (de Alembic)`: punto central para definir el contexto de migraciones con SQLAlchemy.
- **Disponer de un punto de partida reutilizable** para futuros desarrollos con autenticación, endpoints personalizados y más.

### Instalación:

1. **Clona el repositorio** en el directorio de tu elección:

   ```bash
   git clone https://github.com/alexandre-aparicio/fastAPI_SQLAlchemy-PostgreSQL-Alembic.git
   cd fastAPI_SQLAlchemy-PostgreSQL-Alembic

2. **Construye y levanta los contenedores** utilizando Docker Compose   
- Construir el contenedor con las directrices del fichero docker-compose.yml y Dockerfile

    ```bash
    docker compose up --build
- Acceder al contenedor recien creado

    ```bash
    docker exec -it fastapi_sqlalchemy-postgresql-alembic-app-1-app-1 bash
    
- Acceder a la base de datos para comprobar que de ha ejecutado la migración users

    ```bash
    docker exec -it fastapi_sqlalchemy-postgresql-alembic-app-1-db-1 psql -U postgres -d fastapi_db

- Crear una nueva migración 
    - Editamos el fichero app/models.py y añadimos el nuevo modelo

        ```bash
        from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
        from datetime import datetime
        from .database import Base

        class Blog(Base):
            __tablename__ = "blogs"
            
            id = Column(Integer, primary_key=True, index=True)
            title = Column(String(100), nullable=False)
            content = Column(Text, nullable=False)
            author_id = Column(Integer, ForeignKey("users.id"))
            created_at = Column(DateTime, default=datetime.utcnow)
            is_published = Column(Boolean, default=False)
            slug = Column(String(100), unique=True)

    - Generar la migración automática (Dentro del contenedor)  

        ```bash

        alembic revision --autogenerate -m "create blogs table"

    - Aplicar la migración

        ```bash
        alembic upgrade head