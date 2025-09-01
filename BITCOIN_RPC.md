# Bitcoin RPC Methods for memTV

## Core RPC Methods Needed

### 1. getblockcount
Returns the number of blocks in the longest blockchain.
- Parameters: none
- Result: (numeric) The current block count

### 2. getblockhash
Returns hash of block in best-block-chain at height provided.
- Parameters: height (numeric, required)
- Result: (string) The block hash

### 3. getblock
Returns information about a block with the given hash.
- Parameters: 
  - blockhash (string, required)
  - verbosity (numeric, optional, default=1)
- Result (verbosity=1): (string) A string that is serialized, hex-encoded data for block

### 4. getmempoolinfo
Returns details on the active state of the TX memory pool.
- Parameters: none
- Result: object with mempool information

### 5. getrawmempool
Returns all transaction ids in memory pool as a json array of string transaction ids.
- Parameters: 
  - verbose (boolean, optional, default=false)
- Result: (json array) or (json object)

## HTTP Request Format
Bitcoin RPC uses JSON-RPC 1.0 over HTTP POST requests:
```
POST / HTTP/1.1
Host: localhost:8332
Content-Type: application/json

{
  "jsonrpc": "1.0",
  "id": "memTV",
  "method": "getblockcount",
  "params": []
}
```

## Authentication
Uses HTTP Basic Authentication with rpcuser and rpcpassword from bitcoin.conf
