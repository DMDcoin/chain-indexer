# chain-indexer

Indexes DMD Diamond chain data into PostgreSQL: staking epochs, validators, stake movements, rewards, bonus scores and the DMD naming system (`.dmd` names). The data is served by chain-data-service.

- Blocks are read over JSON-RPC and processed one by one, each in a single database transaction.
- On start the indexer continues with the next unprocessed block and then keeps following the chain head.
- `DB_FILL_START_BLOCK` lets an empty database start at a later block; the chain state is read at that block first.

## What is indexed

| Table | Content |
|---|---|
| `headers` | Every block with time, duration, transaction count, staking epoch and the reward, reinsert, governance and claiming pot balances |
| `posdao_epoch`, `posdao_epoch_node` | Staking epochs, their validators and the reward breakdown per pool once an epoch is closed |
| `node` | Validator pools with mining address and public key |
| `delegate_staker`, `delegate_reward` | Delegators and their rewards per epoch and pool |
| `stake_transactions` | Stake, withdrawal, claim and move events |
| `stake_history`, `stake_delegators`, `ordered_withdrawal` | Stake of each pool over block ranges, delegator stakes and ordered withdrawals |
| `available_event`, `pending_validator_state_event` | Validator availability and validator set changes |
| `bonus_score_history`, `bonus_score_change_reasons` | Validator bonus scores and the reason of each change |
| `dmd_names`, `dmd_name_events` | `.dmd` names and their event history |

## Requirements

- Node.js 22
- PostgreSQL 15 with the schema from `db/`
- A JSON-RPC endpoint of the DMD Diamond network

## Configuration

Configuration is read from environment variables. `.env.example` contains a working set for local use.

| Variable | Default | Description |
|---|---|---|
| `DMD_DB_POSTGRES_PASS` | | Password of the `postgres` user, required |
| `POSTGRES_INSTANCE` | `127.0.0.1:5432` | Database address as `host:port` |
| `RPC_URL` | `https://rpc.bit.diamonds` | JSON-RPC endpoint |
| `DB_FILL_START_BLOCK` | | First block to index on an empty database |
| `DB_FILL_STOP_BLOCK` | | Last block to index |
| `DEV_TOOLS_LOG_DEBUG` | `false` | Logs every processing step |
| `DMD_REGISTRAR_CONTROLLER_ADDRESS` | mainnet contract | Naming system registrar controller |
| `DMD_NAMES_ADDRESS` | mainnet contract | Naming system names contract |

The defaults come from the `mainnet` entry in `config/default.json`. Start the indexer with `--network testnet` to use the testnet entry instead.

On the first start a random mnemonic is created in the working directory (`.mnemonic`, `.mainaddress`). The indexer only reads from the chain; the mnemonic is used to set up the web3 account.

## Running

### Docker Compose

```bash
cp .env.example .env    # set the passwords
docker compose up -d db
./scripts/apply-migrations.sh
docker compose up -d indexer
```

This starts PostgreSQL and the indexer. The database is published on `127.0.0.1:5433` only.

### From source

```bash
npm ci
set -a; source .env; set +a
npm run dev                 # generates the contract bindings and starts the indexer
npm run build && npm start  # compiled build
```

### Container image

```bash
docker build -t chain-indexer .
```

The image contains the compiled application and its production dependencies only and runs as the unprivileged `node` user. `/var/lib/chain-indexer` is the working directory and should be a volume, so the mnemonic is kept across restarts.

## Database

`db/` contains the PostgreSQL image. On the first start it creates the tables, indexes, views and the `diamond_api` role used by chain-data-service, with the password from `DMD_DB_API_PASS`.

Schema changes are SQL files in `db/migrations`. `scripts/apply-migrations.sh` applies the ones that have not run yet and records them in the `schema_migrations` table.

## Development

```bash
npm run typecheck
npm run build
```

CI runs the type check and build, builds both container images and applies all migrations to a fresh database.

## License

[AGPL-3.0](LICENSE)
