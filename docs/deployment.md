# DocuSeal production deployment (EC2 / Docker)

Deploy DocuSeal with Docker using PostgreSQL on the same server. App is exposed on port **9090**.

## Quick start

1. **Create `.env`** (copy from `.env.example`) and set at least:
   - `DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/docuseal`
   - `SECRET_KEY_BASE=` (generate with `openssl rand -hex 64`)
   - `HOST=` your domain or server IP

2. **Build and run:**
   ```bash
   cd /var/www/docuseal
   docker compose -f docker-compose.production.yml build
   docker compose -f docker-compose.production.yml up -d
   ```

3. **App URL:** `http://your-server:9090`

## PostgreSQL on same server

- In `postgresql.conf`: `listen_addresses = '*'`
- In `pg_hba.conf`: allow Docker networks, e.g.:
  - `host    docuseal    postgres    172.17.0.0/16    scram-sha-256`
  - `host    docuseal    postgres    172.20.0.0/16    scram-sha-256`  
  Or use `172.16.0.0/12` to cover all typical Docker bridge subnets.
- Create DB: `psql -U postgres -h 127.0.0.1 -c "CREATE DATABASE docuseal OWNER postgres;"`

## Useful commands

| Task | Command |
|------|---------|
| View logs | `docker compose -f docker-compose.production.yml logs -f app` |
| Restart app | `docker compose -f docker-compose.production.yml restart app` |
| Stop | `docker compose -f docker-compose.production.yml down` |
| Run migrations | `docker compose -f docker-compose.production.yml run --rm -w /app app bundle exec rails db:migrate` |
| **Rails console** | `cd /var/www/docuseal` then `docker compose -f docker-compose.production.yml exec app sh -c "cd /app && bin/rails c"` |

### Rails console (copy-paste)

```bash
cd /var/www/docuseal
docker compose -f docker-compose.production.yml exec app sh -c "cd /app && bin/rails c"
```

## Remove the image

```bash
docker compose -f docker-compose.production.yml down
docker rmi docuseal-app
```
