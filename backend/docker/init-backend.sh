#!/bin/bash
set -e

echo "Waiting for database to be ready..."
python -c "
import time
import psycopg
import sys

for i in range(30):
    try:
        psycopg.connect('dbname=nest user=postgres password=postgres host=nest-db port=5432')
        print('Database is ready!')
        sys.exit(0)
    except psycopg.OperationalError:
        print('Waiting for database...')
        time.sleep(1)

print('Database connection failed')
sys.exit(1)
"

echo "Running migrations..."
python manage.py migrate

echo "Loading Nest data (equivalent to make load-data)..."
python manage.py load_data

# Add || true to prevent failures from stopping the script
echo "Indexing Nest data in Algolia..."
python manage.py algolia_reindex || true
python manage.py algolia_update_replicas || true
python manage.py algolia_update_synonyms || true

echo "Backend initialization completed!"
exec "$@"
