# photo-stack

Self-hosted photo backup on a Mac, run with Docker Desktop:

- **Immich** — the main photo library, web UI and iPhone app. Uses Immich's official `docker-compose.yml`, unmodified.
- **icloudpd** — downloads the full iCloud Photos library and checks for new photos every hour.

| What | Where | In git? |
|---|---|---|
| Config (`docker-compose.yml`, `.env.example`, this README) | this repo | yes |
| Secrets (`.env`) | this repo, ignored | **no** — keep a copy in a password manager |
| Immich library + automatic DB dumps | `/Volumes/home_backup/immich` | no |
| iCloud download (+ login cookies in `.cookies/`) | `/Volumes/home_backup/icloud` | no |
| Postgres data | `./postgres` (internal disk; network shares are not supported) | no |

`example.env` is Immich's original template, kept for reference. The real settings are in `.env` (see `.env.example` for the keys).

## First run

1. Start Docker Desktop and mount the external drive at `/Volumes/home_backup`.
2. `cp .env.example .env`, then fill it in. Generate `DB_PASSWORD` with
   `LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32`.
3. Check the config: `docker compose config`
4. Start Immich (everything except icloudpd):
   ```sh
   docker compose up -d immich-server immich-machine-learning redis database
   ```
5. Open http://localhost:2283 and create the admin account.
6. Log in to iCloud once, interactively. icloudpd asks for your password and a 2FA code:
   ```sh
   docker compose run --rm icloudpd icloudpd --directory /data --cookie-directory /data/.cookies --username "$(grep '^APPLE_ID=' .env | cut -d= -f2)" --auth-only
   ```
7. Start the hourly sync: `docker compose up -d icloudpd`

Apple's login session expires about every 2 months. When `docker compose logs icloudpd` shows authentication errors, repeat step 6, then run `docker compose restart icloudpd`.

## Import the iCloud folder into Immich

1. In Immich, go to **Account Settings → API Keys** and create a key.
2. Run the CLI from the Docker image. It mounts the iCloud folder read-only and skips the cookie folder:
   ```sh
   docker run -it --rm \
     -v /Volumes/home_backup/icloud:/import:ro \
     -e IMMICH_INSTANCE_URL=http://host.docker.internal:2283/api \
     -e IMMICH_API_KEY=<your-api-key> \
     ghcr.io/immich-app/immich-cli:latest \
     upload --recursive --ignore '**/.cookies/**' /import
   ```
   Immich skips files it already has, so you can run this again after each sync to import only new photos.

## iPhone app over Tailscale

1. Install Tailscale on the Mac and the iPhone, and sign in to the same account on both.
2. Find the Mac's Tailscale address with `tailscale ip -4` (a `100.x.y.z` address) or use its MagicDNS name (e.g. `my-mac.tailnet-name.ts.net`).
3. In the Immich iPhone app, set the server URL to `http://<that address>:2283` and log in.
4. Optional: in the app, turn on **Backup** to upload new iPhone photos directly.

If the app can't connect, check that the macOS firewall allows incoming connections for Docker.

## Restore on a new machine

1. Install Docker Desktop and git, then clone this repo.
2. Restore `.env` from your password manager. The `DB_PASSWORD` must match the original.
3. Plug in the drive. It must mount at `/Volumes/home_backup`; if the path differs, change `UPLOAD_LOCATION` and `ICLOUD_LOCATION` in `.env`.
4. Restore the database. Use the newest dump in `/Volumes/home_backup/immich/backups/`:
   ```sh
   docker compose create
   docker compose start redis database
   sleep 10
   gunzip --stdout "/Volumes/home_backup/immich/backups/<newest>.sql.gz" \
     | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
     | docker exec -i immich_postgres psql --dbname=postgres --username=postgres
   docker compose up -d immich-server immich-machine-learning redis database
   ```
   Do this before opening Immich in a browser. These steps come from Immich's backup guide: https://docs.immich.app/administration/backup-and-restore
5. Log in to iCloud again (First run, step 6), then run `docker compose up -d icloudpd`.

## Backups

This drive becomes the main copy of your photos, so back it up too. For example, use Time Machine to an APFS disk and remove `home_backup` from Time Machine's exclusion list.
