#!/bin/bash
set -e

echo "Waiting for database to be ready..."
python -c "
import time
import psycopg
import sys

for i in range(30):
    try:
        psycopg.connect('dbname=nest user=postgres password=postgres host=db port=5432')
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

echo "Indexing Nest data in Algolia (equivalent to make index-data)..."
python manage.py algolia_reindex
python manage.py algolia_update_replicas
python manage.py algolia_update_synonyms

echo "Backend initialization completed!"

# Start the actual application
exec "$@"
