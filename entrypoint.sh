#!/bin/sh
set -e

# The indexer derives a web3 account from a mnemonic when it starts.
# A random one is created on the first start and kept in the working directory.
if [ ! -f .mnemonic ]; then
    node /app/dist/localnet/create-random-mnemonic.js
fi

exec node /app/dist/db/runFillDb.js "$@"
