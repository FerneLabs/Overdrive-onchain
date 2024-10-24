use core::num::traits::Zero;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use overdrive::utils;
use overdrive::models::{player_models::{PlayerState, PlayerAccount}};

// Game model
// Keeps track of the state of the game
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct GameState {
    #[key]
    pub id: usize,
    pub player_1: ContractAddress,
    pub player_2: ContractAddress,
    pub status: GameStatus,
    pub mode: GameMode,
    pub winner_address: ContractAddress,
    pub result: (u8, u8),
    pub start_time: u64,
    pub end_time: u64
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
        game_id: usize, player_1: ContractAddress, player_2: ContractAddress, game_mode: GameMode
    ) -> GameState {
        GameState {
            id: game_id,
            player_1,
            player_2,
            status: GameStatus::Ongoing,
            mode: game_mode,
            winner_address: contract_address_const::<0x0>(),
            result: (0, 0),
            start_time: get_block_timestamp(),
            end_time: 0
        }
    }

    fn end_game(
        ref game_state: GameState,
        ref winner_player: PlayerState,
        ref loser_player: PlayerState,
        ref winner_account: PlayerAccount,
        ref loser_account: PlayerAccount
    ) -> () {
        game_state.winner_address = winner_player.player_address;
        // In a SinglePlayer match,
        // always set the real player result as first element in the tuple
        game_state
            .result =
                if (winner_player.is_bot) {
                    (
                        loser_player.score.try_into().unwrap(),
                        winner_player.score.try_into().unwrap()
                    )
                } else {
                    (
                        winner_player.score.try_into().unwrap(),
                        loser_player.score.try_into().unwrap()
                    )
                };

        game_state.status = GameStatus::Ended;
        game_state.end_time = get_block_timestamp();

        winner_account.games_played += 1;
        winner_account.games_won += 1; // TODO: this is not working for some reason

        loser_account.games_played += 1;
    }
}
