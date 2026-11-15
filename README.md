# photo-stack

A self-hosted photo library on a Mac:

- **Immich** — your photo library (web at http://localhost:2283, plus the iPhone app).
- **icloudpd** — downloads everything from iCloud Photos and checks for new photos every hour. Supports two Apple IDs.

Everything is controlled with one command: **`./photo`**. Run it from this folder in Terminal.

---

## Set up (first time, or on a new Mac)

**You need:** a Mac with [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed, and the photo drive plugged in.

1. Get this folder onto the Mac (see [Moving to another Mac](#moving-to-another-mac) if it's coming from an old one).
2. Open Terminal and run:
   ```sh
   cd ~/photo-stack
   ./photo setup
   ```
   It asks for the drive path and Apple IDs, then starts everything.
3. Log in to each iCloud account. Do this in Terminal; it asks for the Apple password and the 6-digit code from the iPhone:
   ```sh
   ./photo login 1
   ./photo login 2      # only if you have a second account
   ```
4. Open http://localhost:2283 and create your Immich account.

That's it. iCloud photos now download in the background.

---

## Everyday commands

| I want to… | Run |
|---|---|
| See download progress | `./photo status` |
| Stop everything (e.g. before unplugging the drive) | `./photo stop` |
| Start everything again | `./photo start` |
| Pause / resume just one account | `./photo stop 2` / `./photo start 2` |
| Watch what it's doing live | `./photo logs` (Ctrl+C to stop watching) |
| Put iCloud photos into Immich | `./photo import 1` (or `2`) |
| Log in again (every ~2 months, or if status says so) | `./photo login 1` (or `2`) |

Stopping is always safe — downloads pick up where they left off.

### Putting iCloud photos into Immich

The iCloud downloads land in folders on the drive. To see them in Immich:

1. In Immich: click your profile picture → **Account Settings** → **API Keys** → **New API Key**, and copy it.
2. Run `./photo import 1` and paste the key.

Use a key from the Immich user who should own the photos — e.g. give the second person their own Immich user and use their key for `./photo import 2`. Running import again later only uploads new photos.

---

## iPhone app (from anywhere, via Tailscale)

1. Install [Tailscale](https://tailscale.com/download) on this Mac and the iPhone, and sign in to the same account on both.
2. On the Mac, run `tailscale ip -4` to get its address (looks like `100.x.y.z`).
3. In the Immich iPhone app, set the server to `http://100.x.y.z:2283` and log in.
4. Optional: turn on **Backup** in the app to upload new iPhone photos directly.

If it can't connect, check that the Mac's firewall allows Docker (System Settings → Network → Firewall).

---

## Moving to another Mac

**On the old Mac:**
```sh
./photo pack
```
This stops everything and saves `photo-stack-transfer-<date>.tar.gz` to the Desktop. It contains your settings and database (but no photos — those are on the drive). It includes your database password, so move it privately (AirDrop or USB) and delete it afterwards. Then eject the drive.

**On the new Mac:** install Docker Desktop, plug in the drive, put the file in your home folder, and run:
```sh
tar -xzf photo-stack-transfer-*.tar.gz -C ~
cd ~/photo-stack
./photo setup
```
Everything comes back as it was, including the iCloud logins. Update the server address in the iPhone app if it changed.

### If the old Mac is lost or broken

You won't have the database, but Immich saves daily database backups on the drive. Get this folder from git (or download it), copy your `.env` back in from your password manager, plug in the drive, and run `./photo setup` — it finds the newest backup on the drive and offers to restore it.

No `.env` either? Run `./photo setup` anyway and answer the questions. Your photos are safe on the drive, but you'll have to set up Immich again and run `./photo import` to bring them back in.

---

## Good to know

- **Keep `.env` safe.** It holds your settings and database password, and it's deliberately not in git. Save a copy in a password manager.
- **Back up the drive.** It holds the main copy of your photos. Time Machine to another drive works — remove `home_backup` from Time Machine's exclusion list.
- **Keep the Mac awake** during big downloads: run `caffeinate -i` in a Terminal window.
- **Drive name matters.** The drive must show up with the same name (e.g. `/Volumes/home_backup`). If it changes, edit the paths in `.env`.

### What's where

| What | Where | In git? |
|---|---|---|
| Config: `photo`, `docker-compose.yml`, `.env.example`, this README | this folder | yes |
| Settings + secrets: `.env` | this folder | **no** |
| Immich database | `./postgres` on this Mac | no |
| Immich library + daily DB backups | `<drive>/immich` | no |
| iCloud downloads (+ saved logins in `.cookies`) | `<drive>/icloud-<apple id>` | no |

`docker-compose.yml` is Immich's official file plus two `icloudpd` services. `example.env` is Immich's original template, kept for reference. The `./photo` script is plain shell — open it to see the exact `docker compose` commands it runs.
