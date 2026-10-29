# MongoDB setup

MongoDB 7 runs in its own container, defined in the repository's root `docker-compose.yml`:

```yaml
  portfolio-mongo:
    image: mongo:7
    container_name: netiks-portfolio-mongo
    ports:
      - "27018:27017"
    volumes:
      - portfolio_mongodata:/data/db
```

The named volume `portfolio_mongodata` is declared under `volumes:` at the bottom of the file.

Start it (this leaves PostgreSQL untouched):

```
docker compose up -d portfolio-mongo
```

Check that it responds:

```
docker exec -it netiks-portfolio-mongo mongosh
db.runCommand({ ping: 1 })
```

Expected result: `{ ok: 1 }`. Evidence: `screenshots/01-mongo-running.png`.

Port 27018 on the host avoids a clash with any local MongoDB on 27017. Authentication is
not enabled, which is acceptable only for a local demonstration database.