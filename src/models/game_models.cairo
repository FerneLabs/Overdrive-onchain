use core::num::traits::Zero;
use starknet::{ContractAddress, contract_address_const};
use starknet::get_block_timestamp;

// Game model
// Keeps track of the state of the game
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: felt252, // Unique id of the game
    pub created_by: ContractAddress, // Address of the game creator
    pub game_status: GameStatus, // Status of the game
    pub game_mode: GameMode, // Mode of the game
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct GamePlayer {
    #[key]
    pub owner: ContractAddress, // Unique id of the game
    #[key]
    pub game_id: felt252, // Unique id of the game
    pub car: u256, // Should be a contractAddress NFT
    pub get_cipher_1: (u256, u256),
    pub get_cipher_2: (u256, u256),
    pub get_cipher_3: (u256, u256),
    pub last_action_timestamp: u64,
    pub score: u256,
    pub energy: u256,
    pub shield: u256,
}

// Represents the game mode
// Can either be SinglePlayer or Multiplayer
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameMode {
    SinglePlayer, // Play with computer
    MultiPlayer, // Play online
}

// Represents the status of the game
// Can either be Ongoing or Ended
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Ongoing,
    Ended,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum CipherTypes {
    Speed,
    Attack,
    Shield,
    Energy
}

pub trait GameTrait {
    // Create and return a new game
    fn new_single_player(created_by: ContractAddress) -> (Game, GamePlayer, GamePlayer);
    fn terminate_game(ref self: Game);
}


impl GameImpl of GameTrait {
    fn new_single_player(created_by: ContractAddress) -> (Game, GamePlayer, GamePlayer) {
        let zero_address = contract_address_const::<0x0>();

        let game = Game {
            id: 1, created_by, game_status: GameStatus::Ongoing, game_mode: GameMode::SinglePlayer,
        };

        let mut player_one = GamePlayer {
            owner: created_by, 
            game_id: 1, 
            car: 1, 
            score: 0, 
            energy: 6, 
            shield: 0, 
            get_cipher_1: (0, 0),
            get_cipher_2: (0, 0), 
            get_cipher_3: (0, 0), 
            last_action_timestamp: get_block_timestamp()
        };

        let mut player_two = GamePlayer {
            owner: zero_address, 
            game_id: 1, 
            car: 1, 
            score: 0, 
            energy: 6, 
            shield: 0, 
            get_cipher_1: (0, 0),
            get_cipher_2: (0, 0), 
            get_cipher_3: (0, 0),
            last_action_timestamp: get_block_timestamp()
        };

        (game, player_one, player_two)
    }

    fn terminate_game(ref self: Game) {
        self.game_status = GameStatus::Ended;
    }
}
