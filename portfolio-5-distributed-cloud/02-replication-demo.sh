#!/usr/bin/env bash
# Portfolio 5: replication, read-only and lag demos.
# Run from anywhere: bash portfolio-5-distributed-cloud/02-replication-demo.sh
# The script pauses after each step so a screenshot can be taken.

cd "$(dirname "$0")/.." || exit 1      # repository root
set -a; source .env; set +a

pg()  { docker exec netiks-portfolio-db      psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
rep() { docker exec netiks-portfolio-replica psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
wait_for() { read -rp "--- screenshot ($1), then press Enter ---"; }

# Always resume replay on exit, so the replica is never left paused.
trap 'rep -qc "SELECT pg_wal_replay_resume();" >/dev/null 2>&1' EXIT

echo "== 1. Replication status =="
pg  -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
rep -c "SELECT pg_is_in_recovery();"
wait_for 01-replication-status.png

echo "== 2. A change on the primary appears on the replica =="
pg  -c "UPDATE catalog.products SET name = 'Product 1 (replicated)' WHERE slug = 'product-1';"
rep -c "SELECT name FROM catalog.products WHERE slug = 'product-1';"
pg  -c "UPDATE catalog.products SET name = 'Product 1' WHERE slug = 'product-1';"
wait_for 02-replication-works.png

echo "== 3. The replica is read-only =="
rep -c "UPDATE catalog.products SET name = 'Hacked' WHERE slug = 'product-1';"
wait_for 03-replica-readonly.png

echo "== 4. Replication lag: pause replay on the replica =="
rep -c "SELECT pg_wal_replay_pause();"
rep -c "SELECT pg_is_wal_replay_paused();"
pg  -c "UPDATE catalog.products SET name = 'Product 1 (new price list)' WHERE slug = 'product-1';"
pg  -c "SELECT 'primary' AS server, name FROM catalog.products WHERE slug = 'product-1';"
rep -c "SELECT 'replica' AS server, name FROM catalog.products WHERE slug = 'product-1';"
pg  -c "SELECT state, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;"
wait_for 04-replication-lag.png

echo "== 5. Resume replay: the replica catches up =="
rep -c "SELECT pg_wal_replay_resume();"
sleep 2
rep -c "SELECT name FROM catalog.products WHERE slug = 'product-1';"
pg  -c "UPDATE catalog.products SET name = 'Product 1' WHERE slug = 'product-1';"
wait_for 05-replica-caught-up.png