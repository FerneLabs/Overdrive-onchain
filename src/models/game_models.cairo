use core::num::traits::Zero;
use starknet::{ContractAddress};
use overdrive::utils;
use overdrive::models::{game_player_models::{GamePlayer, GamePlayerTrait}};

// Game model
// Keeps track of the state of the game
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: usize, // Unique id of the game
    pub player_1: ContractAddress,
    pub player_2: ContractAddress,
    pub game_status: GameStatus, // Status of the game
    pub game_mode: GameMode, // Mode of the game
}

// Represents the game mode
// Can either be SinglePlayer or Multiplayer
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameMode {
    SinglePlayer,
    MultiPlayer,
}

// Represents the status of the game
// Can either be Ongoing or Ended
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Ongoing,
    Ended,
}

pub trait GameTrait {
    fn new_game(
        game_id: usize, player_1: ContractAddress, player_2: ContractAddress
    ) -> (Game, GamePlayer, GamePlayer);
}

impl GameImpl of GameTrait {
    fn new_game(
        game_id: usize, player_1: ContractAddress, player_2: ContractAddress
    ) -> (Game, GamePlayer, GamePlayer) {
        let game = Game {
            id: game_id,
            player_1,
            player_2,
            game_status: GameStatus::Ongoing,
            game_mode: GameMode::SinglePlayer,
        };

        let mut player_one = GamePlayerTrait::new_game_player(player_1, game_id);
        let mut player_two = GamePlayerTrait::new_game_player(player_2, game_id);

        (game, player_one, player_two)
    }
}
