
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

#### See all methods
```bash
./run help
```

#### Build
```bash
./run build
```

#### Create account
```bash
./run create USERNAME
```

#### Create new game `GAME_MODE = 0 (SP) || 1 (MP)`
```bash
./run init GAME_MODE
```

#### Request ciphers for caller address. IS_BOT = 0 || 1. For empty deck send `int:0,IS_BOT`
```bash
./run request DECK_ARRAY,IS_BOT
  # Example usage:
  ./run request int:2,int:1,3,5,int:1,3,1,0
  # Where: 
      # int:2 -> Length of module array
        # int:1 -> Length of Type array
        # 3 -> Type indexes, in this case, single energy cipher
        # 5 -> cipher_value
        ###
        # int:1 -> Length of Type array
        # 3 -> Type indexes, in this case, single energy cipher
        # 1 -> cipher_value
      # 0 -> is_bot = false
```

#### Runs module with cipher values sent. For empty deck send `int:0,IS_BOT`
```bash
./run module MODULE_ARRAY,DECK_ARRAY,IS_BOT
  # Example usage:
  ./run module int:2,int:2,0,0,15,int:2,0,0,20,int:3,int:1,2,5,int:1,3,2,int:1,3,1,0

  # Where: 
    # int:2 -> Length of module array
      # int:2 -> Length of Type array
      # 0,0 -> Type indexes, in this case, pure ADV cipher
      # 15 -> cipher_value
      ###
      # int:3 -> Length of Type array
      # 0,0 -> Type indexes, in this case, pure ADV cipher
      # 20 -> cipher_value
    # int:3 -> Length of deck array
      # int:1 -> Length of Type array
      # 2 -> Type indexes, in this case, single shield cipher 
      # 5 -> cipher_value
      ###
      # int:1 -> Length of Type array
      # 3 -> Type indexes, in this case, single energy cipher 
      # 2 -> cipher_value
      ##
      # int:1 -> Length of Type array
      # 3 -> Type indexes, in this case, single energy cipher 
      # 1 -> cipher_value
    # 0 -> is_bot = false
```
