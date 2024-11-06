
### Run Katana
```bash
./run katana
```

### Build and migrate
```bash
./run build
```

### Run Torii

```bash
./run torii
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
    entities {
      edges {
        node {
          models {
            __typename
            ... on overdrive_PlayerCiphers {
              hack_ciphers {
                cipher_type
                cipher_value
              }
              deck_ciphers {
                cipher_type
                cipher_value
              }
            }
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

# Create new game. GAME_MODE = 0 (SP) || 1 (MP) 
./run init GAME_MODE

# Request ciphers for caller address. IS_BOT = 0 || 1
./run request IS_BOT

# Runs module with cipher values sent
./run module PARAMS
  # Example usage:
  ./run module int:3,0,10,0,10,0,10,0
  # Where: 
    # int:3 -> Length of array
    # 0,10 -> cipher_type,cipher_value
    # 0 -> is_bot = false
  
```
