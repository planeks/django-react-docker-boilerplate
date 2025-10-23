# Running the Project Without Docker

Follow these steps to run the project locally without using Docker:

## 1. Set Up Environment
Create and activate a Python virtual environment in the `src` directory:
```
python -m venv .venv
source .venv/bin/activate
```

## 2. Install Dependencies
Install the required Python packages using `poetry`:
```
cd src
poetry install
```

## 3. Configure Database
- Install and start PostgreSQL locally.
- Create a database matching your environment variables.
- Configure database connection in your `.env` file or Django settings.

## 4. Configure Environment Variables
Make sure all necessary environment variables from the `.env` file are set in your local environment.

## 5. Run Supporting Services
- **PostgreSQL**: Start your local PostgreSQL server.
- **Redis**: Install and run Redis locally.
- **MailHog**: Start MailHog and access the UI at `http://localhost:8025`.

## 6. Migrate Database
```
python manage.py migrate
```

## 7. Run Django Server
Start the Django development server:
```
python manage.py runserver 0.0.0.0:8000
```

## 8. Run Frontend in a Separate Terminal
- Navigate to the `src/frontend` directory.
- Install frontend dependencies:
```
npm install
```
- Start the frontend development server:
```
npm run dev
```

## 9. [Optional] Run Celery Workers and Beat
Run Celery worker:
```
celery -A config worker -l INFO
```
Run Celery beat scheduler:
```
celery -A config beat -l INFO
```

## 10. [Optional] Run Documentation Server (MkDocs)
Start MkDocs server for documentation:
```
mkdocs serve
```

## 11. To start tests, run:

```shell
cd src/
export DJANGO_SETTINGS_MODULE=config.settings.test
exec poetry run pytest
```

---

**Note:**
- Ensure all URLs and credentials in environment variables are properly configured.  
- Install system dependencies for PostgreSQL, Redis, Node.js, and Python as needed.

This setup runs all components locally, replacing the Docker containers.
