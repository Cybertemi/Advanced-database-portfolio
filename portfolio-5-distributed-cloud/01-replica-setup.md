# Replica setup

## 1. Environment
Create `.env` from `.env.example` (`KEY=value`, no spaces, not committed):
```
POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_DB=...
REPLICATION_PASSWORD=...
```

## 2. Prepare the primary
```
set -a; source .env; set +a

docker exec netiks-portfolio-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '$REPLICATION_PASSWORD';"

docker exec netiks-portfolio-db bash -c "echo 'host replication replicator all scram-sha-256' >> /var/lib/postgresql/data/pg_hba.conf"

docker exec netiks-portfolio-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT pg_reload_conf();"
```
The role may use only letters and digits in its password to avoid shell quoting problems.

## 3. Replica service (in the root docker-compose.yml)
```yaml
  portfolio-replica:
    image: postgres:16
    container_name: netiks-portfolio-replica
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_DB: ${POSTGRES_DB}
      PGPASSWORD: ${REPLICATION_PASSWORD}
    ports:
      - "5434:5432"
    volumes:
      - portfolio_replicadata:/var/lib/postgresql/data
    command:
      - bash
      - -c
      - |
        set -e
        if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
          until pg_isready -h portfolio-postgres; do sleep 2; done
          pg_basebackup -h portfolio-postgres -U replicator -D /var/lib/postgresql/data -Fp -Xs -P -R
          chmod 700 /var/lib/postgresql/data
        fi
        exec docker-entrypoint.sh postgres
    depends_on:
      - portfolio-postgres
```
and the volume `portfolio_replicadata:` under `volumes:`.

## 4. Start and check
```
docker compose up -d portfolio-replica
docker logs netiks-portfolio-replica
```
Expect `database system is ready to accept read-only connections` and
`started streaming WAL from primary`. Evidence: `screenshots/00-replica-setup.png`.

## Notes
- `-R` makes the copy a standby that follows the primary.
- `set -e` stops the script at the first failure, so a failed copy shows its real error.
- Local demonstration only: do not reuse these settings in production.