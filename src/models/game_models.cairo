use core::num::traits::Zero;
use starknet::{ContractAddress, contract_address_const};
use overdrive::utils;
use overdrive::models::{player_models::{Player, PlayerTrait}, account_models::{Account, AccountTrait}};

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
    pub winner_address: ContractAddress,
    pub result: (u8, u8)
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
            game_mode,
            winner_address: contract_address_const::<0x0>(),
            result: (0, 0),
        };

        let mut player_one = PlayerTrait::create_player(player_1, game_id);
        let mut player_two = PlayerTrait::create_player(player_2, game_id);

        (game, player_one, player_two)
    }

    fn end_game(
        ref game: Game, 
        ref winner: Player, 
        ref loser: Player, 
        ref winner_account: Account, 
        ref loser_account: Account
    ) -> () {
        game.game_status = GameStatus::Ended;
        game.winner_address = winner.address;
        game.result = (
            winner.score.try_into().unwrap(), 
            loser.score.try_into().unwrap()
        );

        AccountTrait::update_stats(ref winner_account, true);
        AccountTrait::update_stats(ref loser_account, false);
    }
}
