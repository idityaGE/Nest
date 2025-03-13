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

echo "Loading Nest data (equivalent to make load-data)..."
python manage.py load_data

# Skip Algolia indexing if we're in a test/local environment
# if [[ "${DJANGO_CONFIGURATION}" != "Local" && "${SKIP_ALGOLIA_INDEXING}" != "true" ]]; then
echo "Indexing Nest data in Algolia..."
python manage.py algolia_reindex
python manage.py algolia_update_replicas
python manage.py algolia_update_synonyms
# else
#   echo "Skipping Algolia indexing in local/test environment"
# fi

# echo "Loading Nest data (equivalent to make load-data)..."
# make load-data
# echo "Indexing Nest data in Algolia..."
# make index-data

echo "Backend initialization completed!"
exec "$@"
