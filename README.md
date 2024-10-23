
### Run Katana
```bash
katana --disable-fee
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

### GraphQL Queries:

<details>
  <summary>Subscribe to all entity updates</summary>

  ```graphql
  subscription {
    entityUpdated {
      id
      keys
      models {
        __typename
        ... on overdrive_PlayerAccount {
          username
          games_played
          games_won
        }
        ... on overdrive_PlayerState {
          is_bot
          score
          shield
          energy
          playing
        }
        ... on overdrive_PlayerCiphers {
          is_bot
          hack_cipher_1 {
            cipher_type
            cipher_value
          }
          hack_cipher_2 {
            cipher_type
            cipher_value
          }
          hack_cipher_3 {
            cipher_type
            cipher_value
          }
        }
        ... on overdrive_GameState {
          player_1
          player_2
          status
          winner_address
          result {
            _0
            _1
          }
          start_time
          end_time
        }
      }
    }
  }
  ```

</details>

<details>
  <summary>Query Player Accounts</summary>

  ```graphql
  query {
    overdrivePlayerAccountModels {
      edges {
        node {
          player_address
          username
          games_played
          games_won
        }
      }
    }
  }
  ```
  
</details>

<details>
  <summary>Query Player States</summary>

  ```graphql
  query {
    overdrivePlayerStateModels (order: {field: IS_BOT, direction: ASC}) {
      edges {
        node {
          player_address
          is_bot
          game_id
          score
          shield
          playing
        }
      }
    }
  }
  ```
  
</details>

<details>
  <summary>Query Player Ciphers</summary>

  ```graphql
  query {
    overdrivePlayerCiphersModels (order: {field: IS_BOT, direction: ASC}) {
      edges {
        node {
          player_address
          is_bot
          hack_cipher_1 {
            cipher_type
            cipher_value
          }
          hack_cipher_2{
            cipher_type
            cipher_value
          }
          hack_cipher_3{
            cipher_type
            cipher_value
          }
        }
      }
    }
  }
  ```
  
</details>

<details>
  <summary>Query Game States</summary>

  ```graphql
  query {
    overdriveGameStateModels {
      edges {
        node {
          id
          status
          player_1
          player_2
          winner_address
          mode
          result {
            _0
            _1
          }
          start_time
          end_time
        }
      }
    }
  }
  ```
  
</details>

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
./run request IS_BOT

# Runs module with cipher values sent
./run run PARAMS
```
