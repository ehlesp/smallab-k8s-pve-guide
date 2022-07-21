#!/bin/bash
echo ">>> Initializing PostgreSQL server"
set -e

echo ">>> Creating user ${POSTGRESQL_GITEA_USERNAME} for Gitea"
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE ROLE ${POSTGRESQL_GITEA_USERNAME} WITH LOGIN PASSWORD '${POSTGRESQL_GITEA_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_GITEA_USERNAME};
EOSQL


echo ">>> Enabling [pg_stat_statements] module on database ${POSTGRES_DB}"
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE EXTENSION pg_stat_statements;
EOSQL

echo ">>> Creating user and schema ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} for PostgreSQL Prometheus metrics exporter"
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    -- To use IF statements, hence to be able to check if the user exists before
    -- attempting creation, we need to switch to procedural SQL (PL/pgSQL)
    -- instead of standard SQL.
    -- More: https://www.postgresql.org/docs/14/plpgsql-overview.html
    -- To preserve compatibility with <9.0, DO blocks are not used; instead,
    -- a function is created and dropped.
    CREATE OR REPLACE FUNCTION __tmp_create_user() returns void as
    '
    BEGIN
      IF NOT EXISTS (
              SELECT                       -- SELECT list can stay empty for this
              FROM   pg_catalog.pg_user
              WHERE  usename = ''${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}'') THEN
        CREATE USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
      END IF;
    END;
    ' language plpgsql;

    SELECT __tmp_create_user();
    DROP FUNCTION __tmp_create_user();

    ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} WITH PASSWORD '${POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD}';
    ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME},pg_catalog;

    -- If deploying as non-superuser (for example in AWS RDS), uncomment the GRANT
    -- line below and replace <MASTER_USER> with your root user.
    -- GRANT ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO <MASTER_USER>;
    CREATE SCHEMA IF NOT EXISTS ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
    GRANT USAGE ON SCHEMA ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

    CREATE OR REPLACE FUNCTION get_pg_stat_activity() RETURNS SETOF pg_stat_activity AS
    ' SELECT * FROM pg_catalog.pg_stat_activity; '
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity
    AS
      SELECT * from get_pg_stat_activity();

    GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

    CREATE OR REPLACE FUNCTION get_pg_stat_replication() RETURNS SETOF pg_stat_replication AS
    ' SELECT * FROM pg_catalog.pg_stat_replication; '
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication
    AS
      SELECT * FROM get_pg_stat_replication();

    GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

    CREATE OR REPLACE FUNCTION get_pg_stat_statements() RETURNS SETOF pg_stat_statements AS
    ' SELECT * FROM public.pg_stat_statements; '
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements
    AS
      SELECT * FROM get_pg_stat_statements();

    GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
EOSQL
