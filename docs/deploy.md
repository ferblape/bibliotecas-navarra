# Deploying to Fly.io

The app runs on a single Fly Machine in Paris (`cdg`, the region closest to
Spain) at https://bibliotecas-navarra.fly.dev. Its SQLite databases live on a
Fly volume mounted at `/rails/storage`, and Litestream backs them up
continuously to a Tigris bucket.

- `fly.toml`: machine, volume mount, health check on `/up`, auto stop/start.
- `config/litestream.yml`: which databases go to which path in the bucket.
- `bin/docker-entrypoint`: restores missing databases, runs `db:prepare`, and
  starts the server under `litestream replicate`.

The machine stops when idle and starts on the next request, so the first visit
after a quiet period takes a few seconds longer.

## First-time setup

Run from the repository root, where `fly.toml` and `config/master.key` are.

```sh
fly apps create bibliotecas-navarra
fly volumes create storage --app bibliotecas-navarra --region cdg --size 1
fly storage create --app bibliotecas-navarra --name bibliotecas-navarra-backups
fly secrets set --app bibliotecas-navarra --stage RAILS_MASTER_KEY="$(cat config/master.key)"
fly deploy
```

`fly volumes create` warns that a single volume has no redundancy. That is
expected: Litestream is the backup, and Fly also keeps daily volume snapshots
for 5 days.

`fly storage create` sets `BUCKET_NAME`, `AWS_ENDPOINT_URL_S3`,
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as app secrets. It prints the
secret key only once; manage keys afterwards with `fly storage dashboard`.
Without `BUCKET_NAME` the app still runs, without backups.

## Deploy

```sh
fly deploy
```

Migrations run in `bin/docker-entrypoint` when the server boots, not as a
release command: release machines have no volume attached.

Check it with `fly status`, `fly logs` and `fly checks list`.

## Restoring from Litestream

### Lost volume

When the volume has no database, the entrypoint restores the latest backup
before the server starts. Create an empty volume and deploy:

```sh
fly volumes create storage --app bibliotecas-navarra --region cdg --size 1
fly deploy
```

### Back to an earlier point in time

Restore a copy next to the live database, check it, then swap it in. Requests
written between the swap and the restart are lost.

```sh
fly ssh console --app bibliotecas-navarra
cd /rails
litestream ltx -config config/litestream.yml /rails/storage/production.sqlite3
litestream restore -config config/litestream.yml -timestamp 2026-11-15T10:00:00Z \
  -o storage/restored.sqlite3 /rails/storage/production.sqlite3
sqlite3 storage/restored.sqlite3 "select count(*) from lists"
mv storage/restored.sqlite3 storage/production.sqlite3
rm -f storage/production.sqlite3-wal storage/production.sqlite3-shm
chown rails:rails storage/production.sqlite3
exit
fly machine restart --app bibliotecas-navarra
```

`litestream ltx` lists the backups available. `fly machine restart` asks
which machine when there is more than one. The cache database
(`production_cache.sqlite3`) needs no point-in-time restore: delete it and
restart, and `db:prepare` creates it empty.
