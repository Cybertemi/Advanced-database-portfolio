#!/usr/bin/env bash
# Portfolio 5: failover demo, then restore the setup.
# WARNING: stops the primary, promotes the replica, then rebuilds the replica from the
# primary. Only the replica's own volume is deleted.
# Run: bash portfolio-5-distributed-cloud/03-failover-demo.sh

cd "$(dirname "$0")/.." || exit 1
set -a; source .env; set +a

pg()  { docker exec netiks-portfolio-db      psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
rep() { docker exec netiks-portfolio-replica psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
wait_for() { read -rp "--- screenshot ($1), then press Enter ---"; }

echo "== 1. The primary goes down =="
docker stop netiks-portfolio-db
pg -c "SELECT 1;"        # expected to fail: container is not running
wait_for 06-primary-down.png

echo "== 2. The replica still serves reads =="
rep -c "SELECT name, price FROM catalog.products WHERE slug = 'product-1';"
wait_for 07-replica-serves-reads.png

echo "== 3. Writes are refused until promotion, then promote =="
rep -c "UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';"
rep -c "SELECT pg_promote();"
rep -c "SELECT pg_is_in_recovery();"   # f = no longer a standby
rep -c "UPDATE catalog.products SET name = 'Product 1 (after failover)' WHERE slug = 'product-1';"
rep -c "SELECT name FROM catalog.products WHERE slug = 'product-1';"
wait_for 08-promoted-and-writes.png

echo "== 4. Restore: rebuild the replica from the original primary =="
docker compose rm -sf portfolio-replica
VOL=$(docker volume ls -q | grep 'portfolio_replicadata$')
[ -n "$VOL" ] && docker volume rm "$VOL"
docker start netiks-portfolio-db
until docker exec netiks-portfolio-db pg_isready -q; do sleep 2; done
docker compose up -d portfolio-replica
echo "Waiting for the replica to copy and start streaming..."
sleep 30
pg -c "SELECT name FROM catalog.products WHERE slug = 'product-1';"
pg -c "SELECT state FROM pg_stat_replication;"
wait_for 09-setup-restored.png