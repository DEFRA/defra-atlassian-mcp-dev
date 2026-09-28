# defra-atlassian-mcp - Local Development

Local development support for running and developing the defra-atlassian-mcp microservices locally using Docker Compose.

## Prerequisites

- Docker
- Docker Compose
- uv - [Installation Guide](https://docs.astral.sh/uv/getting-started/installation/#installing-uv)
- Python 3.13 or higher — We recommend using uv to manage your Python environment.
- Git

## Repositories

| Service | Repo | Type | Language |
|---------|------|------|----------|
| defra-atlassian-mcp | [DEFRA/defra-atlassian-mcp](https://github.com/DEFRA/defra-atlassian-mcp) | MCP server | Python 3.13 / FastAPI + FastMCP |
| defra-atlassian-mcp-portal | [DEFRA/defra-atlassian-mcp-portal](https://github.com/DEFRA/defra-atlassian-mcp-portal) | Portal frontend | Node.js ≥24 / Hapi |
| mural-api-stub | [DEFRA/mural-api-stub](https://github.com/DEFRA/mural-api-stub) | Mock Mural API (optional) | Python ≥3.12 / FastAPI |

The `mural-api-stub` service is optional and only starts when using the `use-stub-api` compose profile.

## Local Development

Clone this repository and sync the environment before running the scripts.

```bash
git clone https://github.com/DEFRA/defra-atlassian-mcp-dev

cd defra-atlassian-mcp-dev/

uv sync --frozen
```

### Cloning Repositories

This project contains a script to clone all the required repositories. It checks the `service-compose` directory for services and clones any that do not already exist.

```bash
uv run task clone
```

Cloned repositories land in `./repos/`.

### Environment Configuration

Runtime configuration comes from a `.env` file at the repository root.

> [!IMPORTANT]
> The `.env` file must not be committed to version control. It is already listed in `.gitignore`.

An example is provided at `.env.example`:

```bash
cp .env.example .env
```

`.env` is optional — the compose files supply working defaults for every variable, so the stack starts without it. Create one when you need to override defaults (for example, to use real AWS credentials or change the AWS region).

Note that `.env` holds *host*-oriented endpoints, for running a service directly on your machine against dockerised dependencies. The compose files hard-set the container-oriented equivalents over the top.

| Variable | Default | Description |
|---|---|---|
| AWS_REGION | eu-west-2 | Primary AWS region used by services |
| AWS_DEFAULT_REGION | eu-west-2 | Fallback AWS region environment variable |
| AWS_ACCESS_KEY_ID | test | AWS access key (use local/test credentials for local dev) |
| AWS_SECRET_ACCESS_KEY | test | AWS secret key (use local/test credentials for local dev) |
| AWS_EMF_ENVIRONMENT | local | Environment label for EMF (embedded metrics) |
| AWS_EMF_AGENT_ENDPOINT | tcp://0.0.0.0:25888 | EMF agent endpoint for metrics ingestion |
| AWS_EMF_LOG_GROUP_NAME | log-group-name | CloudWatch EMF log group name (local placeholder) |
| AWS_EMF_LOG_STREAM_NAME | log-stream-name | CloudWatch EMF log stream name (local placeholder) |
| AWS_EMF_NAMESPACE | namespace | EMF metrics namespace |
| AWS_EMF_SERVICE_NAME | service-name | Logical service name for EMF metrics |
| AWS_EMF_SERVICE_TYPE | python-backend-service | Service type used by EMF instrumentation |
| FLOCI_ENDPOINT_URL | http://localhost:4566 | LocalStack (floci) endpoint for host-side runs; overridden to `http://floci:4566` in compose |
| CDP_UPLOADER_BASE_URL | http://localhost:7337 | cdp-uploader endpoint for host-side runs; overridden to `http://cdp-uploader:7337` in compose |
| CDP_UPLOADER_BROWSER_URL | http://localhost:7337 | cdp-uploader endpoint as the browser sees it |

### Starting the Services

A single docker-compose project orchestrates both services and their dependencies.

```bash
docker compose up --build
```

To also rebuild automatically when a service's dependency manifest changes (`pyproject.toml`, `package.json`):

```bash
docker compose watch
```

To start the optional API stub service alongside the main stack:

```bash
docker compose --profile use-stub-api up --build
```

To stop the services:

```bash
docker compose down
```

The services can still be started individually from their own repositories. This project exists to give local development a single common entry point.

| Port | Service |
|------|---------|
| 3000 | Portal UI |
| 9229 | Portal Node.js inspector (nodemon debug port) |
| 8085 | defra-atlassian-mcp server |
| 8086 | mural-api-stub (only when `--profile use-stub-api` is used) |
| 4566 | floci (AWS emulator) |
| 27017 | MongoDB |
| 6379 | Redis |
| 7337 | cdp-uploader |

Once up: <http://localhost:3000> for the portal, <http://localhost:8085> for the defra-atlassian-mcp server.

## File Uploads

`cdp-uploader` is included so the document-upload flow can be developed locally. A service starts an upload by POSTing to `http://cdp-uploader:7337/initiate` with a destination bucket and redirect URL; the browser then posts the file to the returned `uploadUrl`. Files land in `cdp-uploader-quarantine`, are virus-scanned (mocked), and clean ones are copied to the destination bucket — `mural-board-handling-forms`, created at startup by `compose/floci/start.d/10-setup-resources.sh`.

Scanning is mocked (`MOCK_VIRUS_SCAN_ENABLED`), so every upload is reported clean after ~3 seconds and no ClamAV container is needed.

Check what has been uploaded so far:

```bash
docker compose exec floci aws s3 ls s3://mural-board-handling-forms --endpoint-url=http://localhost:4566
```

## Live Reload

Both services build their `development` target and bind-mount source from `repos/`:

- **defra-atlassian-mcp** — uvicorn reloads on changes under `app/`.
- **defra-atlassian-mcp-portal** — nodemon reloads on changes under `src`. Server-side code in `src/server` and `src/config` reload automatically. Client-side assets are compiled at image build time, so changes there need `docker compose up --build`.

## Network

All services run on a shared Docker bridge network named `defra-atlassian-mcp` to enable inter-service communication.

## Script Documentation

### Clone

Clones the repository for each microservice into `./repos/`.

```bash
uv run task clone
```

### Pull

Pulls the latest remote changes for each microservice on its current branch.

```bash
uv run task pull
```

### Update

Switches to and pulls the latest main branch for each microservice.

```bash
uv run task update
```
