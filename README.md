
### Run Katana
```bash
katana --disable-fee --allowed-origins "*"
```

### Build and migrate
```bash
./run build
```

### Run Torii

```bash
torii --world 0x611ff61e3381fcab007822cddc4ab3c68983b1450cc61e37eefbbf7699e116d
```  
### Go to GraphQL playground:  
[http://localhost:8080/graphql](http://localhost:8080/graphql)  

### Subscribe to all entity updates:  
```graphql
subscription {
  entityUpdated {
    id
    keys
    models {
      __typename
      ... on overdrive_Player {
        score
        shield
        energy
        get_cipher_1 {
          cipher_type
          cipher_value
        }
        get_cipher_2 {
          cipher_type
          cipher_value
        }
        get_cipher_3 {
          cipher_type
          cipher_value
        }
      }
      ... on overdrive_Game {
        player_1
        player_2
        game_status
        winner_address
        result {
          _0
          _1
        }
      }
      ... on overdrive_Account {
        address
        total_games_played
        total_games_won
      }
  	}
	}
}
```

### Interact with world
```bash
# See all methods
./run help

# Build
./run build

# Create account
./run create USERNAME

# Create game - Game ID is returned in Katana
# GAME_MODE = 0 for SinglePlayer
./run init GAME_MODE

# Request ciphers for caller address
./run request

# Fetch state of game and its players
./run state GAME_ID

# Set new player values depending on cipher sent, applies to caller address
./run set PARAMS
```
