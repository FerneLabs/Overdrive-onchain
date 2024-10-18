use core::num::traits::Zero;
use starknet::{ContractAddress};
use overdrive::utils;
use overdrive::models::{player_models::{Player, PlayerTrait}};

// Game model
// Keeps track of the state of the game
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: usize,
    pub player_1: ContractAddress,
    pub player_2: ContractAddress,
    pub game_status: GameStatus,
    pub game_mode: GameMode,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameMode {
    SinglePlayer,
    MultiPlayer,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Ongoing,
    Ended,
}

#[generate_trait]
impl GameImpl of GameTrait {
    fn new_game(
        game_id: usize, 
        player_1: ContractAddress, 
        player_2: ContractAddress,
        game_mode: GameMode
    ) -> (Game, Player, Player) {
        let game = Game {
            id: game_id,
            player_1,
            player_2,
            game_status: GameStatus::Ongoing,
            game_mode
        };

        let mut player_one = PlayerTrait::create_player(player_1, game_id);
        let mut player_two = PlayerTrait::create_player(player_2, game_id);

        (game, player_one, player_two)
    }
}
