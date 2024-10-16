#### Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*"
```

#### Terminal two
```bash
# Build
./run build

# Create account
./run create USERNAME

# Create game - Game ID is returned in Katana
./run init

# Request ciphers for caller address
./run request

# Fetch state of game and its players
./run state GAME_ID

# Set new player values depending on cipher sent, applies to caller address
./run set CIPHER_VALUE CIPHER_TYPE
```
